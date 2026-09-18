import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dine_pulse/shared/models/shared_queue_entry_model.dart';
import 'package:dine_pulse/shared/services/firestore_collections.dart';
import 'package:dine_pulse/shared/services/table_repository.dart';

/// Queue Repository
/// Enforces:
/// - Duplicate prevention
/// - Available tables dynamically affect wait calculation
/// - Reserved/occupied/cleaning tables CANNOT be assigned to queue customers
class SharedQueueRepository {
  FirebaseFirestore? _firestore;
  final SharedTableRepository tableRepo;

  // In-memory fallback
  final List<SharedQueueEntryModel> _mockQueue = [];
  final StreamController<List<SharedQueueEntryModel>> _queueStreamCtrl =
      StreamController<List<SharedQueueEntryModel>>.broadcast();

  SharedQueueRepository({required this.tableRepo}) {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestore = FirebaseFirestore.instance;
      }
    } catch (e) {
      debugPrint('Firestore initialization notice: $e');
    }
    _seedMockQueue();
  }

  void _seedMockQueue() {
    final now = DateTime.now();
    _mockQueue.addAll([
      SharedQueueEntryModel(
        id: 'q_1',
        ticketNumber: 'Q-101',
        restaurantId: 'rest1',
        customerId: 'user_cust_2',
        customerName: 'Nimal Fernando',
        customerPhone: '+94 71 987 6543',
        partySize: 2,
        position: 1,
        status: SharedQueueStatus.waiting,
        initialWaitMinutes: 15,
        estimatedWaitMinutes: 5,
        joinedAt: now.subtract(const Duration(minutes: 10)),
      ),
      SharedQueueEntryModel(
        id: 'q_2',
        ticketNumber: 'Q-102',
        restaurantId: 'rest1',
        customerId: 'user_cust_3',
        customerName: 'Anuki Jayawardena',
        customerPhone: '+94 76 555 4321',
        partySize: 4,
        position: 2,
        status: SharedQueueStatus.waiting,
        initialWaitMinutes: 25,
        estimatedWaitMinutes: 12,
        joinedAt: now.subtract(const Duration(minutes: 5)),
      ),
    ]);
  }

  // ─── Stream Active Queue ───────────────────────────────────────────────────
  Stream<List<SharedQueueEntryModel>> streamActiveQueue(String restaurantId) {
    if (_firestore != null) {
      return _firestore!
          .collection(FirestoreCollections.queueEntries)
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', whereIn: [
            SharedQueueStatus.waiting,
            SharedQueueStatus.almostTurn,
            SharedQueueStatus.called,
          ])
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => SharedQueueEntryModel.fromFirestore(doc.data(), doc.id))
              .toList());
    }
    return Stream.value(
      _mockQueue.where((q) => q.restaurantId == restaurantId && q.isActive).toList(),
    );
  }

  // ─── Rule: Duplicate Prevention ───────────────────────────────────────────
  Future<SharedQueueEntryModel?> getActiveTicketForCustomer(
    String customerId,
    String restaurantId,
  ) async {
    if (_firestore != null) {
      final snap = await _firestore!
          .collection(FirestoreCollections.queueEntries)
          .where('customerId', isEqualTo: customerId)
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', whereIn: [
            SharedQueueStatus.waiting,
            SharedQueueStatus.almostTurn,
            SharedQueueStatus.called,
          ])
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        return SharedQueueEntryModel.fromFirestore(
          snap.docs.first.data(),
          snap.docs.first.id,
        );
      }
      return null;
    }

    try {
      return _mockQueue.firstWhere(
        (q) => q.customerId == customerId && q.restaurantId == restaurantId && q.isActive,
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Rule 3: Available Tables Affect Queue Wait Calculation ───────────────
  Future<int> calculateDynamicWaitTime({
    required String restaurantId,
    required int partySize,
  }) async {
    final activeQueue = _mockQueue.where((q) => q.restaurantId == restaurantId && q.isActive).toList();
    final partiesAhead = activeQueue.where((q) => q.partySize <= partySize + 2).length;

    // Available tables reducing wait time
    final availableFittingTables = await tableRepo.getAvailableTablesCount(
      restaurantId,
      forPartySize: partySize,
    );

    int baseRate = partySize <= 2 ? 6 : (partySize <= 4 ? 9 : 14);
    final calculated = (partiesAhead * baseRate) - (availableFittingTables * 4);
    return calculated < 5 ? 5 : calculated;
  }

  // ─── Join Queue (With Duplicate Check) ─────────────────────────────────────
  Future<SharedQueueEntryModel?> joinQueue(SharedQueueEntryModel entry) async {
    final existing = await getActiveTicketForCustomer(entry.customerId, entry.restaurantId);
    if (existing != null) {
      debugPrint('Duplicate queue blocked: customer ${entry.customerId} already has ticket ${existing.ticketNumber}');
      return existing;
    }

    if (_firestore != null) {
      try {
        final doc = await _firestore!
            .collection(FirestoreCollections.queueEntries)
            .add(entry.toFirestore());
        return entry.copyWith(id: doc.id);
      } catch (e) {
        debugPrint('Firestore queue entry creation error: $e');
      }
    }

    _mockQueue.add(entry);
    _queueStreamCtrl.add(_mockQueue);
    return entry;
  }

  // ─── Rule 2: Seat Customer at Table (Reserved Tables CANNOT be assigned) ───
  Future<bool> seatCustomerAtTable({
    required String ticketId,
    required String restaurantId,
    required String tableId,
    required String staffId,
  }) async {
    SharedQueueEntryModel? ticket;
    try {
      ticket = _mockQueue.firstWhere((q) => q.id == ticketId);
    } catch (_) {}

    final customerName = ticket?.customerName ?? 'Queue Guest';
    final partySize = ticket?.partySize ?? 2;

    // Call table repo: Enforces that reserved/occupied/cleaning CANNOT be assigned!
    final seated = await tableRepo.seatQueueCustomerAtTable(
      restaurantId: restaurantId,
      tableId: tableId,
      queueTicketId: ticketId,
      customerName: customerName,
      partySize: partySize,
    );

    if (!seated) {
      debugPrint('Seating rejected: table is reserved, occupied, or cleaning!');
      return false;
    }

    // Update queue entry status to seated
    if (_firestore != null) {
      await _firestore!
          .collection(FirestoreCollections.queueEntries)
          .doc(ticketId)
          .update({
        'status': SharedQueueStatus.seated,
        'assignedTableId': tableId,
        'seatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    }

    if (ticket != null) {
      final idx = _mockQueue.indexOf(ticket);
      _mockQueue[idx] = ticket.copyWith(
        status: SharedQueueStatus.seated,
        assignedTableId: tableId,
        seatedAt: DateTime.now(),
      );
      _queueStreamCtrl.add(_mockQueue);
      return true;
    }
    return false;
  }
}
