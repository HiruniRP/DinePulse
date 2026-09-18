import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dine_pulse/shared/models/shared_reservation_model.dart';
import 'package:dine_pulse/shared/services/firestore_collections.dart';
import 'package:dine_pulse/shared/services/table_repository.dart';

/// Reservation Repository
/// Enforces Member 1 requirement (Show reservations belonging to logged-in customer)
/// and Member 2 requirement (Atomically lock reserved table in Firestore).
class SharedReservationRepository {
  FirebaseFirestore? _firestore;
  final SharedTableRepository tableRepo;

  // In-memory fallback
  final List<SharedReservationModel> _mockReservations = [];
  final StreamController<List<SharedReservationModel>> _resStreamCtrl =
      StreamController<List<SharedReservationModel>>.broadcast();

  SharedReservationRepository({required this.tableRepo}) {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestore = FirebaseFirestore.instance;
      }
    } catch (e) {
      debugPrint('Firestore initialization notice: $e');
    }
    _seedMockReservations();
  }

  void _seedMockReservations() {
    final now = DateTime.now();
    _mockReservations.addAll([
      SharedReservationModel(
        id: 'res_1',
        bookingId: 'DP-82910',
        customerId: 'user_cust_1',
        customerName: 'Kamal Silva',
        customerPhone: '+94 77 123 4567',
        customerEmail: 'customer@dinepulse.com',
        restaurantId: 'rest1',
        restaurantName: 'The Grand Heritage',
        tableId: 'tbl_3',
        tableNumber: '3',
        date: now.add(const Duration(days: 1)),
        timeSlot: '19:30',
        partySize: 4,
        status: SharedReservationStatus.confirmed,
        specialOccasion: 'Birthday',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      SharedReservationModel(
        id: 'res_2',
        bookingId: 'DP-82911',
        customerId: 'user_cust_1',
        customerName: 'Kamal Silva',
        customerPhone: '+94 77 123 4567',
        customerEmail: 'customer@dinepulse.com',
        restaurantId: 'rest2',
        restaurantName: 'Ocean Breeze Seafood',
        date: now.subtract(const Duration(days: 5)),
        timeSlot: '18:00',
        partySize: 2,
        status: SharedReservationStatus.completed,
        createdAt: now.subtract(const Duration(days: 6)),
      ),
    ]);
  }

  // ─── Rule 5: Show Reservation Data Belonging to the Logged-in Customer ────
  Stream<List<SharedReservationModel>> streamCustomerReservations(String customerId) {
    if (_firestore != null) {
      return _firestore!
          .collection(FirestoreCollections.reservations)
          .where('customerId', isEqualTo: customerId)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => SharedReservationModel.fromFirestore(doc.data(), doc.id))
              .toList());
    }
    return Stream.value(
      _mockReservations.where((r) => r.customerId == customerId).toList(),
    );
  }

  // ─── Staff: Stream Restaurant Reservations ─────────────────────────────────
  Stream<List<SharedReservationModel>> streamRestaurantReservations(String restaurantId) {
    if (_firestore != null) {
      return _firestore!
          .collection(FirestoreCollections.reservations)
          .where('restaurantId', isEqualTo: restaurantId)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => SharedReservationModel.fromFirestore(doc.data(), doc.id))
              .toList());
    }
    return Stream.value(
      _mockReservations.where((r) => r.restaurantId == restaurantId).toList(),
    );
  }

  // ─── Rule 1: Member 2 Reservation Creation (Atomic Table Lock) ──────────────
  Future<SharedReservationModel?> createReservation(SharedReservationModel res) async {
    // If a table is assigned, lock table atomically first!
    if (res.tableId != null) {
      final locked = await tableRepo.lockTableForReservation(
        restaurantId: res.restaurantId,
        tableId: res.tableId!,
        reservationId: res.id,
        customerName: res.customerName,
      );
      if (!locked) {
        debugPrint('Failed to lock table ${res.tableId} for reservation.');
        return null;
      }
    }

    if (_firestore != null) {
      try {
        final docRef = await _firestore!
            .collection(FirestoreCollections.reservations)
            .add(res.toFirestore());
        return res.copyWith(
          id: docRef.id,
          status: SharedReservationStatus.confirmed,
        );
      } catch (e) {
        debugPrint('Error writing reservation to Firestore: $e');
      }
    }

    // In-memory update
    _mockReservations.insert(0, res);
    _resStreamCtrl.add(_mockReservations);
    return res;
  }

  // ─── Cancel Reservation (Releases Table Automatically) ──────────────────────
  Future<bool> cancelReservation({
    required String reservationId,
    required String reason,
  }) async {
    SharedReservationModel? target;
    try {
      target = _mockReservations.firstWhere((r) => r.id == reservationId);
    } catch (_) {}

    // Release table if one was locked
    if (target?.tableId != null) {
      await tableRepo.releaseTable(
        restaurantId: target!.restaurantId,
        tableId: target.tableId!,
        startCleaning: false,
      );
    }

    if (_firestore != null) {
      await _firestore!
          .collection(FirestoreCollections.reservations)
          .doc(reservationId)
          .update({
        'status': SharedReservationStatus.cancelled,
        'cancellationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    }

    if (target != null) {
      final idx = _mockReservations.indexOf(target);
      _mockReservations[idx] = target.copyWith(
        status: SharedReservationStatus.cancelled,
        cancellationReason: reason,
        updatedAt: DateTime.now(),
      );
      _resStreamCtrl.add(_mockReservations);
      return true;
    }
    return false;
  }
}
