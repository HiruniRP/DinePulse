import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dine_pulse/shared/models/shared_table_model.dart';
import 'package:dine_pulse/shared/services/firestore_collections.dart';

/// Table Repository implementing cross-module synchronization:
/// - Member 2 Reservation: table.status = reserved
/// - Member 4 Queue: reserved, occupied, and cleaning tables CANNOT be assigned to queue customers
/// - Available tables dynamically affect wait calculation
class SharedTableRepository {
  FirebaseFirestore? _firestore;

  // In-memory cache & fallback when Firestore is offline or testing
  final Map<String, List<SharedTableModel>> _mockTables = {};
  final StreamController<List<SharedTableModel>> _tablesStreamCtrl =
      StreamController<List<SharedTableModel>>.broadcast();

  SharedTableRepository() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestore = FirebaseFirestore.instance;
      }
    } catch (e) {
      debugPrint('Firestore initialization notice: $e (using in-memory table repository)');
    }
    _seedMockTables();
  }

  void _seedMockTables() {
    const rId = 'rest1';
    _mockTables[rId] = [
      const SharedTableModel(id: 'tbl_1', restaurantId: rId, number: '1', capacity: 2, location: 'Indoor', status: SharedTableStatus.available),
      const SharedTableModel(id: 'tbl_2', restaurantId: rId, number: '2', capacity: 2, location: 'Indoor', status: SharedTableStatus.occupied, currentCustomerName: 'Mr. Perera'),
      // Reserved table from Member 2 reservation sync
      const SharedTableModel(id: 'tbl_3', restaurantId: rId, number: '3', capacity: 4, location: 'Window', status: SharedTableStatus.reserved, currentCustomerName: 'Member 2 Booking DP-101'),
      const SharedTableModel(id: 'tbl_4', restaurantId: rId, number: '4', capacity: 4, location: 'Indoor', status: SharedTableStatus.available),
      const SharedTableModel(id: 'tbl_5', restaurantId: rId, number: '5', capacity: 4, location: 'Booth', status: SharedTableStatus.cleaning),
      const SharedTableModel(id: 'tbl_6', restaurantId: rId, number: '6', capacity: 6, location: 'Outdoor', status: SharedTableStatus.available),
      const SharedTableModel(id: 'tbl_7', restaurantId: rId, number: '7', capacity: 6, location: 'Private', status: SharedTableStatus.reserved, currentCustomerName: 'VIP Member 2 Booking DP-102'),
      const SharedTableModel(id: 'tbl_8', restaurantId: rId, number: '8', capacity: 8, location: 'Indoor', status: SharedTableStatus.available),
    ];
  }

  // ─── Real-Time Table Stream ────────────────────────────────────────────────
  Stream<List<SharedTableModel>> streamTablesByRestaurant(String restaurantId) {
    if (_firestore != null) {
      return _firestore!
          .collection(FirestoreCollections.restaurants)
          .doc(restaurantId)
          .collection(FirestoreCollections.tables)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => SharedTableModel.fromFirestore(doc.data(), doc.id))
              .toList());
    }
    // Return stream from in-memory cache
    return Stream.value(_mockTables[restaurantId] ?? []);
  }

  Future<List<SharedTableModel>> getTables(String restaurantId) async {
    if (_firestore != null) {
      final snap = await _firestore!
          .collection(FirestoreCollections.restaurants)
          .doc(restaurantId)
          .collection(FirestoreCollections.tables)
          .get();
      return snap.docs
          .map((doc) => SharedTableModel.fromFirestore(doc.data(), doc.id))
          .toList();
    }
    return _mockTables[restaurantId] ?? [];
  }

  // ─── Rule 1: Member 2 Reservation Locks Table (table.status = reserved) ───
  Future<bool> lockTableForReservation({
    required String restaurantId,
    required String tableId,
    required String reservationId,
    required String customerName,
  }) async {
    if (_firestore != null) {
      try {
        final tableRef = _firestore!
            .collection(FirestoreCollections.restaurants)
            .doc(restaurantId)
            .collection(FirestoreCollections.tables)
            .doc(tableId);

        // Firestore Transaction: Ensures table is available before locking
        return await _firestore!.runTransaction<bool>((transaction) async {
          final tableSnap = await transaction.get(tableRef);
          if (!tableSnap.exists) return false;

          final status = tableSnap.data()?['status'];
          if (status != SharedTableStatus.available) {
            debugPrint('Cannot reserve table $tableId: current status is $status');
            return false;
          }

          transaction.update(tableRef, {
            'status': SharedTableStatus.reserved,
            'currentReservationId': reservationId,
            'currentCustomerName': customerName,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return true;
        });
      } catch (e) {
        debugPrint('Firestore transaction failed for lockTableForReservation: $e');
        return false;
      }
    }

    // In-memory transaction simulation
    final list = _mockTables[restaurantId];
    if (list != null) {
      final idx = list.indexWhere((t) => t.id == tableId);
      if (idx != -1 && list[idx].isAvailable) {
        list[idx] = list[idx].copyWith(
          status: SharedTableStatus.reserved,
          currentReservationId: reservationId,
          currentCustomerName: customerName,
          updatedAt: DateTime.now(),
        );
        _tablesStreamCtrl.add(list);
        return true;
      }
    }
    return false;
  }

  // ─── Rule 2: Member 4 Queue Seating (Reserved/Occupied/Cleaning CANNOT be assigned) ───
  Future<bool> seatQueueCustomerAtTable({
    required String restaurantId,
    required String tableId,
    required String queueTicketId,
    required String customerName,
    required int partySize,
  }) async {
    if (_firestore != null) {
      try {
        final tableRef = _firestore!
            .collection(FirestoreCollections.restaurants)
            .doc(restaurantId)
            .collection(FirestoreCollections.tables)
            .doc(tableId);

        return await _firestore!.runTransaction<bool>((transaction) async {
          final tableSnap = await transaction.get(tableRef);
          if (!tableSnap.exists) return false;

          final data = tableSnap.data();
          final status = data?['status'];
          final capacity = (data?['capacity'] as num?)?.toInt() ?? 0;

          // RULE ENFORCEMENT: Reserved, occupied, cleaning CANNOT be assigned
          if (status != SharedTableStatus.available) {
            debugPrint('Member 4 Seating Blocked: Table $tableId is $status');
            return false;
          }

          if (capacity < partySize) {
            debugPrint('Table capacity ($capacity) insufficient for party ($partySize)');
            return false;
          }

          transaction.update(tableRef, {
            'status': SharedTableStatus.occupied,
            'currentQueueTicketId': queueTicketId,
            'currentCustomerName': customerName,
            'seatedTime': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return true;
        });
      } catch (e) {
        debugPrint('Firestore transaction error: $e');
        return false;
      }
    }

    // In-memory enforcement
    final list = _mockTables[restaurantId];
    if (list != null) {
      final idx = list.indexWhere((t) => t.id == tableId);
      if (idx != -1) {
        final tbl = list[idx];
        if (!tbl.canAssignToQueue || tbl.capacity < partySize) return false;

        list[idx] = tbl.copyWith(
          status: SharedTableStatus.occupied,
          currentQueueTicketId: queueTicketId,
          currentCustomerName: customerName,
          seatedTime: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _tablesStreamCtrl.add(list);
        return true;
      }
    }
    return false;
  }

  // ─── Table Release & Cleaning ──────────────────────────────────────────────
  Future<void> releaseTable({
    required String restaurantId,
    required String tableId,
    bool startCleaning = true,
  }) async {
    final newStatus = startCleaning ? SharedTableStatus.cleaning : SharedTableStatus.available;

    if (_firestore != null) {
      await _firestore!
          .collection(FirestoreCollections.restaurants)
          .doc(restaurantId)
          .collection(FirestoreCollections.tables)
          .doc(tableId)
          .update({
        'status': newStatus,
        'currentReservationId': null,
        'currentQueueTicketId': null,
        'currentCustomerName': null,
        'cleaningStartedAt': startCleaning ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    final list = _mockTables[restaurantId];
    if (list != null) {
      final idx = list.indexWhere((t) => t.id == tableId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(
          status: newStatus,
          currentReservationId: null,
          currentQueueTicketId: null,
          currentCustomerName: null,
          cleaningStartedAt: startCleaning ? DateTime.now() : null,
          updatedAt: DateTime.now(),
        );
        _tablesStreamCtrl.add(list);
      }
    }
  }

  // ─── Rule 3: Available Tables Affecting Queue Wait Calculation ─────────────
  Future<int> getAvailableTablesCount(String restaurantId, {int? forPartySize}) async {
    final tables = await getTables(restaurantId);
    if (forPartySize != null) {
      return tables.where((t) => t.isAvailable && t.capacity >= forPartySize).length;
    }
    return tables.where((t) => t.isAvailable).length;
  }
}
