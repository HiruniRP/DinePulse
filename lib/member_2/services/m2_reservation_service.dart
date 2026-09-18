import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:dine_pulse/member_2/models/m2_reservation_model.dart';
import 'package:dine_pulse/member_1/models/restaurant_model.dart';

/// Member 2 — Reservation Service
/// Firebase-ready: all methods are stubbed with mock data.
/// Replace TODO sections with Firestore calls when Firebase is configured.
class M2ReservationService extends ChangeNotifier {
  final List<M2ReservationModel> _reservations = [];
  final List<M2TableModel> _tables = [];
  bool _isLoading = false;
  String? _error;

  List<M2ReservationModel> get reservations => List.unmodifiable(_reservations);
  List<M2TableModel> get tables => List.unmodifiable(_tables);
  bool get isLoading => _isLoading;
  String? get error => _error;

  M2ReservationService() {
    _seedMockData();
  }

  // ─── Mock Seed ───────────────────────────────────────────────────────────────
  void _seedMockData() {
    // Mock tables for demo restaurant
    _tables.addAll([
      const M2TableModel(id: 't1', number: 'T1', capacity: 2, location: 'indoor', status: M2TableStatus.available),
      const M2TableModel(id: 't2', number: 'T2', capacity: 4, location: 'indoor', status: M2TableStatus.reserved),
      const M2TableModel(id: 't3', number: 'T3', capacity: 4, location: 'indoor', status: M2TableStatus.available),
      const M2TableModel(id: 't4', number: 'T4', capacity: 6, location: 'indoor', status: M2TableStatus.occupied),
      const M2TableModel(id: 't5', number: 'T5', capacity: 6, location: 'outdoor', status: M2TableStatus.available),
      const M2TableModel(id: 't6', number: 'T6', capacity: 8, location: 'outdoor', status: M2TableStatus.available),
      const M2TableModel(id: 't7', number: 'T7', capacity: 2, location: 'bar', status: M2TableStatus.available),
      const M2TableModel(id: 't8', number: 'T8', capacity: 2, location: 'bar', status: M2TableStatus.cleaning),
      const M2TableModel(id: 't9', number: 'T9', capacity: 10, location: 'private', status: M2TableStatus.available, hasWindowView: true),
      const M2TableModel(id: 't10', number: 'T10', capacity: 4, location: 'indoor', status: M2TableStatus.available, isAccessible: true, hasWindowView: true),
    ]);

    final now = DateTime.now();
    _reservations.addAll([
      M2ReservationModel(
        id: 'r1', bookingId: 'DP-20240929-001',
        customerId: 'cust1', customerName: 'Amal Fernando', customerPhone: '+94771234567', customerEmail: 'amal@email.com',
        restaurantId: 'rest1', restaurantName: 'The Spice Route', restaurantImage: '',
        date: now.add(const Duration(days: 1)), time: '7:00 PM', partySize: 4,
        tableLocation: 'indoor', status: M2ReservationStatus.confirmed,
        assignedTableId: 't3', assignedTableNumber: 'T3',
        specialOccasion: 'anniversary',
        smsReminder: true, emailReminder: true, reminderMinutes: 60,
        cancellationPolicyAccepted: true,
        auditTrail: [
          M2AuditEntry(action: 'created', actorId: 'cust1', actorName: 'Amal Fernando', actorRole: 'customer', timestamp: now.subtract(const Duration(hours: 5))),
          M2AuditEntry(action: 'confirmed', actorId: 'staff1', actorName: 'Staff User', actorRole: 'staff', timestamp: now.subtract(const Duration(hours: 4))),
        ],
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      M2ReservationModel(
        id: 'r2', bookingId: 'DP-20240929-002',
        customerId: 'cust2', customerName: 'Nimali Perera', customerPhone: '+94772345678', customerEmail: 'nimali@email.com',
        restaurantId: 'rest1', restaurantName: 'The Spice Route', restaurantImage: '',
        date: now.add(const Duration(days: 2)), time: '12:30 PM', partySize: 2,
        tableLocation: 'outdoor', status: M2ReservationStatus.pending,
        smsReminder: true, emailReminder: false, reminderMinutes: 30,
        cancellationPolicyAccepted: true,
        auditTrail: [M2AuditEntry(action: 'created', actorId: 'cust2', actorName: 'Nimali Perera', actorRole: 'customer', timestamp: now.subtract(const Duration(hours: 2)))],
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      M2ReservationModel(
        id: 'r3', bookingId: 'DP-20240929-003',
        customerId: 'cust3', customerName: 'Kasun Silva', customerPhone: '+94773456789', customerEmail: 'kasun@email.com',
        restaurantId: 'rest1', restaurantName: 'The Spice Route', restaurantImage: '',
        date: now.subtract(const Duration(days: 1)), time: '8:00 PM', partySize: 6,
        tableLocation: 'private', status: M2ReservationStatus.completed,
        assignedTableId: 't9', assignedTableNumber: 'T9',
        preOrderItems: [
          const M2PreOrderItem(menuItemId: 'm1', menuItemName: 'Grilled Chicken', quantity: 2, unitPrice: 1800),
          const M2PreOrderItem(menuItemId: 'm2', menuItemName: 'Fish Curry', quantity: 1, unitPrice: 1500),
        ],
        cancellationPolicyAccepted: true,
        auditTrail: [
          M2AuditEntry(action: 'created', actorId: 'cust3', actorName: 'Kasun Silva', actorRole: 'customer', timestamp: now.subtract(const Duration(days: 3))),
          M2AuditEntry(action: 'confirmed', actorId: 'staff1', actorName: 'Staff User', actorRole: 'staff', timestamp: now.subtract(const Duration(days: 2))),
          M2AuditEntry(action: 'completed', actorId: 'staff1', actorName: 'Staff User', actorRole: 'staff', timestamp: now.subtract(const Duration(hours: 22))),
        ],
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ]);
  }

  // ─── Booking ID Generator ────────────────────────────────────────────────────
  String _generateBookingId() {
    final now = DateTime.now();
    final rnd = (Random().nextInt(900) + 100).toString();
    return 'DP-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$rnd';
  }

  // ─── Table Availability ──────────────────────────────────────────────────────
  List<M2TableModel> getAvailableTables({
    required int partySize,
    required DateTime date,
    required String time,
    String? location,
  }) {
    // TODO: Replace with Firestore query filtering by date/time/status
    return _tables.where((t) {
      final sizeOk = t.capacity >= partySize;
      final available = t.status == M2TableStatus.available;
      final locationOk = location == null || location == 'any' || t.location == location;
      return sizeOk && available && locationOk;
    }).toList();
  }

  List<M2TableModel> getTablesForRestaurant(String restaurantId) {
    // TODO: stream from Firestore: restaurants/{restaurantId}/tables
    return _tables;
  }

  // ─── Smart Time Suggestions ──────────────────────────────────────────────────
  List<String> getSmartTimeSuggestions({required DateTime date, required int partySize}) {
    const allSlots = [
      '11:00 AM', '11:30 AM', '12:00 PM', '12:30 PM',
      '1:00 PM', '1:30 PM', '2:00 PM',
      '6:00 PM', '6:30 PM', '7:00 PM', '7:30 PM', '8:00 PM', '8:30 PM', '9:00 PM',
    ];
    // TODO: Filter out already-booked slots from Firestore
    final existing = _reservations.where((r) =>
      r.date.year == date.year && r.date.month == date.month && r.date.day == date.day &&
      r.status != M2ReservationStatus.cancelled).map((r) => r.time).toSet();
    return allSlots.where((s) => !existing.contains(s)).toList();
  }

  // ─── Customer Reservations ───────────────────────────────────────────────────
  List<M2ReservationModel> getCustomerReservations(String customerId) {
    // TODO: Firestore query: reservations.where('customerId', isEqualTo: customerId).snapshots()
    return _reservations.where((r) => r.customerId == customerId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ─── Staff Reservations ──────────────────────────────────────────────────────
  List<M2ReservationModel> getStaffReservations({
    String? statusFilter,
    DateTime? dateFilter,
    int? partySizeMin,
    int? partySizeMax,
  }) {
    // TODO: Firestore query with filters
    var list = List<M2ReservationModel>.from(_reservations);
    if (statusFilter != null && statusFilter != 'all') {
      list = list.where((r) => r.status == statusFilter).toList();
    }
    if (dateFilter != null) {
      list = list.where((r) =>
        r.date.year == dateFilter.year &&
        r.date.month == dateFilter.month &&
        r.date.day == dateFilter.day).toList();
    }
    if (partySizeMin != null) list = list.where((r) => r.partySize >= partySizeMin).toList();
    if (partySizeMax != null) list = list.where((r) => r.partySize <= partySizeMax).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  // ─── Create Reservation ──────────────────────────────────────────────────────
  Future<M2ReservationModel?> createReservation({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required RestaurantModel restaurant,
    required DateTime date,
    required String time,
    required int partySize,
    String? preferredTableId,
    String? preferredTableNumber,
    String tableLocation = 'any',
    String? specialRequests,
    String? specialOccasion,
    bool isRecurring = false,
    String? recurringPattern,
    int? recurringCount,
    List<M2PreOrderItem> preOrderItems = const [],
    bool depositRequired = false,
    double? depositAmount,
    bool smsReminder = true,
    bool emailReminder = true,
    int reminderMinutes = 60,
    bool cancellationPolicyAccepted = false,
  }) async {
    _setLoading(true);
    try {
      // TODO: Firestore transaction:
      // 1. Check table availability
      // 2. Create reservation doc
      // 3. Update table status to 'reserved'
      await Future.delayed(const Duration(milliseconds: 800)); // simulate network

      final id = 'res_${DateTime.now().millisecondsSinceEpoch}';
      final bookingId = _generateBookingId();
      final now = DateTime.now();

      final reservation = M2ReservationModel(
        id: id,
        bookingId: bookingId,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        restaurantId: restaurant.id,
        restaurantName: restaurant.name,
        restaurantImage: restaurant.imageUrls.isNotEmpty ? restaurant.imageUrls.first : '',
        date: date,
        time: time,
        partySize: partySize,
        preferredTableId: preferredTableId,
        preferredTableNumber: preferredTableNumber,
        tableLocation: tableLocation,
        status: M2ReservationStatus.pending,
        specialRequests: specialRequests,
        specialOccasion: specialOccasion,
        isRecurring: isRecurring,
        recurringPattern: recurringPattern,
        recurringCount: recurringCount,
        preOrderItems: preOrderItems,
        depositRequired: depositRequired,
        depositAmount: depositAmount,
        smsReminder: smsReminder,
        emailReminder: emailReminder,
        reminderMinutes: reminderMinutes,
        cancellationPolicyAccepted: cancellationPolicyAccepted,
        auditTrail: [
          M2AuditEntry(
            action: 'created',
            actorId: customerId,
            actorName: customerName,
            actorRole: 'customer',
            timestamp: now,
          ),
        ],
        createdAt: now,
      );

      _reservations.insert(0, reservation);
      _setLoading(false);
      return reservation;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
    }
  }

  // ─── Modify Reservation (Customer) ──────────────────────────────────────────
  Future<bool> modifyReservation({
    required String reservationId,
    required String actorId,
    required String actorName,
    DateTime? newDate,
    String? newTime,
    int? newPartySize,
    String? newSpecialRequests,
    String? newSpecialOccasion,
    String? newTableLocation,
  }) async {
    _setLoading(true);
    try {
      // TODO: Firestore transaction to update and append modification record
      await Future.delayed(const Duration(milliseconds: 600));
      final idx = _reservations.indexWhere((r) => r.id == reservationId);
      if (idx == -1) { _setLoading(false); return false; }
      final old = _reservations[idx];
      final mods = <M2ModificationRecord>[];
      if (newDate != null && newDate != old.date) {
        mods.add(M2ModificationRecord(field: 'date', oldValue: old.date.toIso8601String(), newValue: newDate.toIso8601String(), changedAt: DateTime.now(), changedBy: actorId));
      }
      if (newTime != null && newTime != old.time) {
        mods.add(M2ModificationRecord(field: 'time', oldValue: old.time, newValue: newTime, changedAt: DateTime.now(), changedBy: actorId));
      }
      if (newPartySize != null && newPartySize != old.partySize) {
        mods.add(M2ModificationRecord(field: 'partySize', oldValue: old.partySize.toString(), newValue: newPartySize.toString(), changedAt: DateTime.now(), changedBy: actorId));
      }
      final updated = old.copyWith(
        date: newDate,
        time: newTime,
        partySize: newPartySize,
        specialRequests: newSpecialRequests,
        specialOccasion: newSpecialOccasion,
        tableLocation: newTableLocation,
        status: M2ReservationStatus.modified,
        modificationHistory: [...old.modificationHistory, ...mods],
        auditTrail: [...old.auditTrail, M2AuditEntry(action: 'modified', actorId: actorId, actorName: actorName, actorRole: 'customer', timestamp: DateTime.now())],
      );
      _reservations[idx] = updated;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ─── Cancel Reservation (Customer) ──────────────────────────────────────────
  Future<bool> cancelReservation({
    required String reservationId,
    required String actorId,
    required String actorName,
    required String reason,
  }) async {
    _setLoading(true);
    try {
      // TODO: Firestore transaction to cancel and free table
      await Future.delayed(const Duration(milliseconds: 600));
      final idx = _reservations.indexWhere((r) => r.id == reservationId);
      if (idx == -1) { _setLoading(false); return false; }
      final old = _reservations[idx];
      final updated = old.copyWith(
        status: M2ReservationStatus.cancelled,
        cancellationReason: reason,
        auditTrail: [...old.auditTrail, M2AuditEntry(action: 'cancelled', actorId: actorId, actorName: actorName, actorRole: 'customer', timestamp: DateTime.now(), notes: reason)],
      );
      _reservations[idx] = updated;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ─── Staff: Confirm Reservation ──────────────────────────────────────────────
  Future<bool> staffConfirmReservation({
    required String reservationId,
    required String staffId,
    required String staffName,
    String? tableId,
    String? tableNumber,
    String? shiftNotes,
  }) async {
    _setLoading(true);
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final idx = _reservations.indexWhere((r) => r.id == reservationId);
      if (idx == -1) { _setLoading(false); return false; }
      final old = _reservations[idx];
      final updated = old.copyWith(
        status: M2ReservationStatus.confirmed,
        assignedTableId: tableId,
        assignedTableNumber: tableNumber,
        staffId: staffId,
        staffName: staffName,
        shiftNotes: shiftNotes,
        auditTrail: [...old.auditTrail, M2AuditEntry(action: 'confirmed', actorId: staffId, actorName: staffName, actorRole: 'staff', timestamp: DateTime.now(), notes: shiftNotes)],
      );
      _reservations[idx] = updated;
      // Update table status
      if (tableId != null) {
        final ti = _tables.indexWhere((t) => t.id == tableId);
        if (ti != -1) _tables[ti] = _tables[ti].copyWith(status: M2TableStatus.reserved, currentReservationId: reservationId);
      }
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ─── Staff: Reject Reservation ───────────────────────────────────────────────
  Future<bool> staffRejectReservation({
    required String reservationId,
    required String staffId,
    required String staffName,
    required String reason,
  }) async {
    _setLoading(true);
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final idx = _reservations.indexWhere((r) => r.id == reservationId);
      if (idx == -1) { _setLoading(false); return false; }
      final old = _reservations[idx];
      final updated = old.copyWith(
        status: M2ReservationStatus.rejected,
        cancellationReason: reason,
        staffId: staffId,
        staffName: staffName,
        auditTrail: [...old.auditTrail, M2AuditEntry(action: 'rejected', actorId: staffId, actorName: staffName, actorRole: 'staff', timestamp: DateTime.now(), notes: reason)],
      );
      _reservations[idx] = updated;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ─── Staff: Bulk Status Update ────────────────────────────────────────────────
  Future<bool> staffBulkUpdateStatus({
    required List<String> reservationIds,
    required String newStatus,
    required String staffId,
    required String staffName,
  }) async {
    _setLoading(true);
    try {
      await Future.delayed(const Duration(milliseconds: 700));
      for (final rid in reservationIds) {
        final idx = _reservations.indexWhere((r) => r.id == rid);
        if (idx == -1) continue;
        final old = _reservations[idx];
        _reservations[idx] = old.copyWith(
          status: newStatus,
          staffId: staffId,
          staffName: staffName,
          auditTrail: [...old.auditTrail, M2AuditEntry(action: 'bulk_update:$newStatus', actorId: staffId, actorName: staffName, actorRole: 'staff', timestamp: DateTime.now())],
        );
      }
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ─── Staff: Assign Table ──────────────────────────────────────────────────────
  Future<bool> staffAssignTable({
    required String reservationId,
    required String tableId,
    required String tableNumber,
    required String staffId,
    required String staffName,
  }) async {
    _setLoading(true);
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      final idx = _reservations.indexWhere((r) => r.id == reservationId);
      if (idx == -1) { _setLoading(false); return false; }
      final old = _reservations[idx];
      _reservations[idx] = old.copyWith(
        assignedTableId: tableId,
        assignedTableNumber: tableNumber,
        auditTrail: [...old.auditTrail, M2AuditEntry(action: 'table_assigned', actorId: staffId, actorName: staffName, actorRole: 'staff', timestamp: DateTime.now(), notes: 'Table $tableNumber assigned')],
      );
      final ti = _tables.indexWhere((t) => t.id == tableId);
      if (ti != -1) _tables[ti] = _tables[ti].copyWith(status: M2TableStatus.reserved, currentReservationId: reservationId);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  M2ReservationModel? getById(String id) {
    try { return _reservations.firstWhere((r) => r.id == id); }
    catch (_) { return null; }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
