import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dine_pulse/member_4/models/m4_queue_model.dart';

/// Member 4: Virtual Queue & Table Management Service
/// Provides real-time stream updates, concurrency-safe transactions,
/// dynamic wait time calculation, and table-queue synchronization.
class M4QueueService extends ChangeNotifier {
  // In-memory persistent queue and tables with mock Firestore transactions
  final List<M4QueueTicket> _tickets = [];
  final List<M4TableItem> _tables = [];
  final Map<String, M4QueueConfig> _configs = {};

  // Concurrency mutex simulation to prevent race conditions between staff
  final Set<String> _lockedTicketIds = {};
  final Set<String> _lockedTableIds = {};

  // Active timers
  Timer? _countdownTimer;
  Timer? _cleaningTimer;

  // Selected language
  M4Language _currentLanguage = M4Language.english;
  M4Language get currentLanguage => _currentLanguage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _lastError;
  String? get lastError => _lastError;

  // Public getters
  List<M4QueueTicket> get allTickets => List.unmodifiable(_tickets);
  List<M4TableItem> get allTables => List.unmodifiable(_tables);

  M4QueueService() {
    _seedInitialData();
    _startBackgroundTimers();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _cleaningTimer?.cancel();
    super.dispose();
  }

  void setLanguage(M4Language lang) {
    _currentLanguage = lang;
    notifyListeners();
  }

  // ─── Initial Seed Data ───────────────────────────────────────────────────────
  void _seedInitialData() {
    const restaurantId = 'rest1';
    final now = DateTime.now();

    // Default configuration for restaurant
    _configs[restaurantId] = const M4QueueConfig(
      isQueueOpen: true,
      baseWaitPerPartyMinutes: 8,
      peakPredictionMessage: 'Peak dinner rush active. Wait times ~10 mins longer.',
    );

    // Seed Tables (including tables reserved by Member 2 to ensure sync!)
    _tables.addAll([
      const M4TableItem(id: 'tbl_1', number: '1', capacity: 2, location: 'Indoor', status: M4TableStatus.available),
      const M4TableItem(id: 'tbl_2', number: '2', capacity: 2, location: 'Indoor', status: M4TableStatus.occupied, currentCustomerName: 'Mr. Perera'),
      // Reserved table from Member 2 reservation sync: CANNOT be assigned to queue
      const M4TableItem(id: 'tbl_3', number: '3', capacity: 4, location: 'Window', status: M4TableStatus.reservedM2, currentCustomerName: 'Reservation (Member 2)'),
      const M4TableItem(id: 'tbl_4', number: '4', capacity: 4, location: 'Indoor', status: M4TableStatus.available),
      const M4TableItem(id: 'tbl_5', number: '5', capacity: 4, location: 'Booth', status: M4TableStatus.cleaning, cleaningStartedAt: null),
      const M4TableItem(id: 'tbl_6', number: '6', capacity: 6, location: 'Outdoor', status: M4TableStatus.available),
      const M4TableItem(id: 'tbl_7', number: '7', capacity: 6, location: 'Private', status: M4TableStatus.reservedM2, currentCustomerName: 'VIP Reservation (Member 2)'),
      const M4TableItem(id: 'tbl_8', number: '8', capacity: 8, location: 'Indoor', status: M4TableStatus.available),
    ]);

    // Seed Initial Queue Tickets
    _tickets.addAll([
      M4QueueTicket(
        id: 'tkt_101',
        ticketNumber: 'Q-101',
        restaurantId: restaurantId,
        restaurantName: 'The Grand Heritage',
        customerId: 'demo_cust_1',
        customerName: 'Kamal Silva',
        customerPhone: '+94 77 123 4567',
        partySize: 2,
        seatingPreference: 'Indoor',
        needsHighChair: false,
        needsWheelchair: false,
        prefersQuietCorner: true,
        specialNotes: 'Anniversary celebration',
        notificationChannel: M4NotificationChannel.whatsapp,
        status: M4QueueStatus.waiting,
        position: 1,
        initialWaitMinutes: 15,
        estimatedWaitMinutes: 5,
        joinedAt: now.subtract(const Duration(minutes: 18)),
        auditTrail: [
          M4QueueAuditEntry(action: 'Joined virtual queue', timestamp: now.subtract(const Duration(minutes: 18)), actor: 'Kamal Silva'),
        ],
      ),
      M4QueueTicket(
        id: 'tkt_102',
        ticketNumber: 'Q-102',
        restaurantId: restaurantId,
        restaurantName: 'The Grand Heritage',
        customerId: 'demo_cust_2',
        customerName: 'Nimal Fernando',
        customerPhone: '+94 71 987 6543',
        partySize: 4,
        seatingPreference: 'Booth',
        needsHighChair: true,
        needsWheelchair: false,
        prefersQuietCorner: false,
        notificationChannel: M4NotificationChannel.sms,
        status: M4QueueStatus.waiting,
        position: 2,
        initialWaitMinutes: 25,
        estimatedWaitMinutes: 12,
        joinedAt: now.subtract(const Duration(minutes: 12)),
        auditTrail: [
          M4QueueAuditEntry(action: 'Joined virtual queue', timestamp: now.subtract(const Duration(minutes: 12)), actor: 'Nimal Fernando'),
        ],
      ),
      M4QueueTicket(
        id: 'tkt_103',
        ticketNumber: 'Q-103',
        restaurantId: restaurantId,
        restaurantName: 'The Grand Heritage',
        customerId: 'demo_cust_3',
        customerName: 'Anuki Jayawardena',
        customerPhone: '+94 76 555 4321',
        partySize: 6,
        seatingPreference: 'Outdoor',
        needsHighChair: false,
        needsWheelchair: true,
        prefersQuietCorner: false,
        notificationChannel: M4NotificationChannel.push,
        status: M4QueueStatus.waiting,
        position: 3,
        initialWaitMinutes: 40,
        estimatedWaitMinutes: 25,
        joinedAt: now.subtract(const Duration(minutes: 5)),
        auditTrail: [
          M4QueueAuditEntry(action: 'Joined virtual queue', timestamp: now.subtract(const Duration(minutes: 5)), actor: 'Anuki Jayawardena'),
        ],
      ),
    ]);
  }

  // ─── Background Timers ───────────────────────────────────────────────────────
  void _startBackgroundTimers() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      bool changed = false;
      for (int i = 0; i < _tickets.length; i++) {
        final t = _tickets[i];
        if (t.status == M4QueueStatus.called && t.callCountdownSeconds > 0) {
          final updated = t.copyWith(callCountdownSeconds: t.callCountdownSeconds - 1);
          _tickets[i] = updated;
          changed = true;
          // Auto-mark expired if countdown reaches 0
          if (updated.callCountdownSeconds <= 0) {
            _tickets[i] = updated.copyWith(
              status: M4QueueStatus.expired,
              auditTrail: [
                ...updated.auditTrail,
                M4QueueAuditEntry(action: 'Call expired (5-min countdown ended)', timestamp: DateTime.now(), actor: 'System'),
              ],
            );
          }
        }
      }
      if (changed) notifyListeners();
    });

    _cleaningTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      // Periodic check for cleaning tables completing
      bool changed = false;
      for (int i = 0; i < _tables.length; i++) {
        final tbl = _tables[i];
        if (tbl.status == M4TableStatus.cleaning && tbl.cleaningStartedAt != null) {
          final elapsed = DateTime.now().difference(tbl.cleaningStartedAt!).inSeconds;
          if (elapsed >= tbl.cleaningDurationSeconds) {
            _tables[i] = tbl.copyWith(status: M4TableStatus.available, cleaningStartedAt: null);
            changed = true;
          }
        }
      }
      if (changed) notifyListeners();
    });
  }

  // ─── Queue Configuration ───────────────────────────────────────────────────
  M4QueueConfig getConfig(String restaurantId) {
    return _configs[restaurantId] ?? const M4QueueConfig();
  }

  void toggleQueueOpen(String restaurantId, bool isOpen, {String? reason}) {
    final current = getConfig(restaurantId);
    _configs[restaurantId] = current.copyWith(
      isQueueOpen: isOpen,
      pauseReason: isOpen ? null : (reason ?? 'Queue temporarily paused by manager'),
    );
    notifyListeners();
  }

  // ─── Customer: Join Queue ───────────────────────────────────────────────────
  Future<M4QueueTicket?> joinQueue({
    required String restaurantId,
    required String restaurantName,
    required String customerId,
    required String customerName,
    required String customerPhone,
    required int partySize,
    String seatingPreference = 'Any',
    bool needsHighChair = false,
    bool needsWheelchair = false,
    bool prefersQuietCorner = false,
    String? specialNotes,
    String notificationChannel = M4NotificationChannel.push,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 600)); // Simulate Firestore latency

      // 1. Check if queue is paused/closed
      final config = getConfig(restaurantId);
      if (!config.isQueueOpen) {
        _lastError = config.pauseReason ?? 'Queue is currently closed by the restaurant.';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      // 2. Duplicate Prevention: Check if customer already has active ticket in this restaurant
      final existing = getActiveCustomerTicket(customerId, restaurantId);
      if (existing != null) {
        _lastError = 'You already have an active ticket (#${existing.ticketNumber}) in this queue.';
        _isLoading = false;
        notifyListeners();
        return existing;
      }

      // 3. Dynamic Wait Time Calculation
      final activeQueue = getActiveQueue(restaurantId);
      final waitEstimate = calculateDynamicWaitTime(restaurantId, partySize);

      // 4. Generate Ticket
      final ticketNum = 'Q-${101 + _tickets.length}';
      final newTicket = M4QueueTicket(
        id: 'tkt_${DateTime.now().millisecondsSinceEpoch}',
        ticketNumber: ticketNum,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        partySize: partySize,
        seatingPreference: seatingPreference,
        needsHighChair: needsHighChair,
        needsWheelchair: needsWheelchair,
        prefersQuietCorner: prefersQuietCorner,
        specialNotes: specialNotes,
        notificationChannel: notificationChannel,
        status: M4QueueStatus.waiting,
        position: activeQueue.length + 1,
        initialWaitMinutes: waitEstimate,
        estimatedWaitMinutes: waitEstimate,
        joinedAt: DateTime.now(),
        auditTrail: [
          M4QueueAuditEntry(
            action: 'Joined virtual queue (Pos #${activeQueue.length + 1})',
            timestamp: DateTime.now(),
            actor: customerName,
          ),
        ],
      );

      _tickets.add(newTicket);
      _recalculatePositions(restaurantId);

      _isLoading = false;
      notifyListeners();
      return newTicket;
    } catch (e) {
      _lastError = 'Failed to join queue: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ─── Customer: Leave Queue ──────────────────────────────────────────────────
  Future<bool> leaveQueue(String ticketId, {String reason = 'Customer decided to leave'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 400));
      final idx = _tickets.indexWhere((t) => t.id == ticketId);
      if (idx == -1) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final t = _tickets[idx];
      _tickets[idx] = t.copyWith(
        status: M4QueueStatus.cancelled,
        auditTrail: [
          ...t.auditTrail,
          M4QueueAuditEntry(action: 'Left queue: $reason', timestamp: DateTime.now(), actor: t.customerName),
        ],
      );

      _recalculatePositions(t.restaurantId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Customer: Wait-Elsewhere Mode ──────────────────────────────────────────
  void setWaitElsewhere(String ticketId, bool active, {double radiusMeters = 500}) {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx != -1) {
      final t = _tickets[idx];
      _tickets[idx] = t.copyWith(
        waitElsewhereActive: active,
        waitElsewhereRadiusMeters: radiusMeters,
        auditTrail: [
          ...t.auditTrail,
          M4QueueAuditEntry(
            action: active ? 'Enabled Wait-Elsewhere ($radiusMeters m)' : 'Disabled Wait-Elsewhere',
            timestamp: DateTime.now(),
            actor: t.customerName,
          ),
        ],
      );
      notifyListeners();
    }
  }

  // ─── Staff: Call Next Customer (Concurrency-Protected) ─────────────────────
  Future<bool> callNextCustomer(String ticketId, {required String staffId, required String staffName}) async {
    // 1. Transaction Mutex check: prevent two staff from calling the same ticket
    if (_lockedTicketIds.contains(ticketId)) {
      _lastError = 'Another staff member is currently processing this ticket.';
      notifyListeners();
      return false;
    }
    _lockedTicketIds.add(ticketId);

    try {
      await Future.delayed(const Duration(milliseconds: 400));
      final idx = _tickets.indexWhere((t) => t.id == ticketId);
      if (idx == -1) return false;

      final t = _tickets[idx];
      // Atomic status verification
      if (t.status != M4QueueStatus.waiting && t.status != M4QueueStatus.almostTurn) {
        _lastError = 'Ticket is no longer waiting in line.';
        return false;
      }

      _tickets[idx] = t.copyWith(
        status: M4QueueStatus.called,
        calledAt: DateTime.now(),
        callCountdownSeconds: 300, // 5 minute countdown
        auditTrail: [
          ...t.auditTrail,
          M4QueueAuditEntry(
            action: 'Called customer (5-minute countdown started)',
            timestamp: DateTime.now(),
            actor: '$staffName ($staffId)',
          ),
        ],
      );

      _recalculatePositions(t.restaurantId);
      notifyListeners();
      return true;
    } finally {
      _lockedTicketIds.remove(ticketId);
    }
  }

  // ─── Staff: Assign & Seat Customer (Concurrency-Protected) ──────────────────
  Future<bool> seatCustomer({
    required String ticketId,
    required String tableId,
    required String staffId,
    required String staffName,
  }) async {
    // Lock both table and ticket
    if (_lockedTableIds.contains(tableId) || _lockedTicketIds.contains(ticketId)) {
      _lastError = 'Table or ticket is currently locked by another operation.';
      notifyListeners();
      return false;
    }
    _lockedTableIds.add(tableId);
    _lockedTicketIds.add(ticketId);

    try {
      await Future.delayed(const Duration(milliseconds: 450));

      final tableIdx = _tables.indexWhere((tbl) => tbl.id == tableId);
      final ticketIdx = _tickets.indexWhere((t) => t.id == ticketId);
      if (tableIdx == -1 || ticketIdx == -1) return false;

      final table = _tables[tableIdx];
      final ticket = _tickets[ticketIdx];

      // Security check: Reserved tables from Member 2 must NEVER be assigned to queue
      if (table.status == M4TableStatus.reservedM2) {
        _lastError = 'Table ${table.number} is reserved by Member 2 and cannot be assigned to queue guests.';
        notifyListeners();
        return false;
      }

      if (table.status != M4TableStatus.available) {
        _lastError = 'Table ${table.number} is not available (Status: ${table.status}).';
        notifyListeners();
        return false;
      }

      // Capacity verification
      if (table.capacity < ticket.partySize) {
        _lastError = 'Table capacity (${table.capacity}) is less than party size (${ticket.partySize}).';
        notifyListeners();
        return false;
      }

      // Update table to occupied
      _tables[tableIdx] = table.copyWith(
        status: M4TableStatus.occupied,
        currentQueueTicketId: ticket.id,
        currentCustomerName: ticket.customerName,
        seatedTime: DateTime.now(),
      );

      // Update ticket to seated
      _tickets[ticketIdx] = ticket.copyWith(
        status: M4QueueStatus.seated,
        seatedAt: DateTime.now(),
        assignedTableId: table.id,
        assignedTableNumber: table.number,
        auditTrail: [
          ...ticket.auditTrail,
          M4QueueAuditEntry(
            action: 'Seated at Table #${table.number}',
            timestamp: DateTime.now(),
            actor: '$staffName ($staffId)',
          ),
        ],
      );

      _recalculatePositions(ticket.restaurantId);
      notifyListeners();
      return true;
    } finally {
      _lockedTableIds.remove(tableId);
      _lockedTicketIds.remove(ticketId);
    }
  }

  // ─── Staff: Skip or Mark No-Show ────────────────────────────────────────────
  Future<bool> markNoShowOrSkip(String ticketId, {bool isNoShow = true, required String staffName}) async {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) return false;

    final t = _tickets[idx];
    _tickets[idx] = t.copyWith(
      status: isNoShow ? M4QueueStatus.noShow : M4QueueStatus.waiting,
      auditTrail: [
        ...t.auditTrail,
        M4QueueAuditEntry(
          action: isNoShow ? 'Marked No-Show by staff' : 'Skipped & bumped down',
          timestamp: DateTime.now(),
          actor: staffName,
        ),
      ],
    );

    _recalculatePositions(t.restaurantId);
    notifyListeners();
    return true;
  }

  // ─── Staff: Add Walk-In ─────────────────────────────────────────────────────
  Future<M4QueueTicket?> addWalkIn({
    required String restaurantId,
    required String restaurantName,
    required String customerName,
    required String customerPhone,
    required int partySize,
    String seatingPreference = 'Any',
    bool needsHighChair = false,
    bool needsWheelchair = false,
    String? staffNotes,
    required String staffName,
  }) async {
    _isLoading = true;
    notifyListeners();

    final activeQueue = getActiveQueue(restaurantId);
    final waitEstimate = calculateDynamicWaitTime(restaurantId, partySize);
    final ticketNum = 'W-${201 + _tickets.length}';

    final ticket = M4QueueTicket(
      id: 'walk_${DateTime.now().millisecondsSinceEpoch}',
      ticketNumber: ticketNum,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      customerId: 'walkin_${DateTime.now().millisecondsSinceEpoch}',
      customerName: customerName,
      customerPhone: customerPhone,
      partySize: partySize,
      seatingPreference: seatingPreference,
      needsHighChair: needsHighChair,
      needsWheelchair: needsWheelchair,
      isWalkIn: true,
      staffNotes: staffNotes,
      status: M4QueueStatus.waiting,
      position: activeQueue.length + 1,
      initialWaitMinutes: waitEstimate,
      estimatedWaitMinutes: waitEstimate,
      joinedAt: DateTime.now(),
      auditTrail: [
        M4QueueAuditEntry(action: 'Walk-in added by host', timestamp: DateTime.now(), actor: staffName),
      ],
    );

    _tickets.add(ticket);
    _recalculatePositions(restaurantId);
    _isLoading = false;
    notifyListeners();
    return ticket;
  }

  // ─── Staff: Priority Reorder ────────────────────────────────────────────────
  void reorderPriority(String ticketId, int newPosition, {required String staffName}) {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx == -1) return;

    final t = _tickets[idx];
    _tickets[idx] = t.copyWith(
      isPriority: true,
      auditTrail: [
        ...t.auditTrail,
        M4QueueAuditEntry(action: 'Promoted to priority (Pos #$newPosition)', timestamp: DateTime.now(), actor: staffName),
      ],
    );
    notifyListeners();
  }

  // ─── Staff: Update Notes ────────────────────────────────────────────────────
  void updateStaffNotes(String ticketId, String notes) {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx != -1) {
      _tickets[idx] = _tickets[idx].copyWith(staffNotes: notes);
      notifyListeners();
    }
  }

  // ─── Table Management ───────────────────────────────────────────────────────
  void updateTableStatus(String tableId, String newStatus) {
    final idx = _tables.indexWhere((t) => t.id == tableId);
    if (idx != -1) {
      final tbl = _tables[idx];
      _tables[idx] = tbl.copyWith(
        status: newStatus,
        currentQueueTicketId: newStatus == M4TableStatus.available ? null : tbl.currentQueueTicketId,
        currentCustomerName: newStatus == M4TableStatus.available ? null : tbl.currentCustomerName,
      );
      notifyListeners();
    }
  }

  void startCleaningTable(String tableId) {
    final idx = _tables.indexWhere((t) => t.id == tableId);
    if (idx != -1) {
      _tables[idx] = _tables[idx].copyWith(
        status: M4TableStatus.cleaning,
        cleaningStartedAt: DateTime.now(),
        currentQueueTicketId: null,
        currentCustomerName: null,
      );
      notifyListeners();
    }
  }

  /// Cross-module sync: Mark table reserved by Member 2 reservation
  void markTableReservedFromM2({required String tableNumberOrId, required String customerName}) {
    final idx = _tables.indexWhere((t) => t.id == tableNumberOrId || t.number == tableNumberOrId);
    if (idx != -1) {
      _tables[idx] = _tables[idx].copyWith(
        status: M4TableStatus.reservedM2,
        currentCustomerName: customerName.isNotEmpty ? customerName : 'Reservation (Member 2)',
      );
      notifyListeners();
    }
  }

  /// Cross-module sync: Release table reserved by Member 2
  void releaseTableFromM2({required String tableNumberOrId}) {
    final idx = _tables.indexWhere((t) => t.id == tableNumberOrId || t.number == tableNumberOrId);
    if (idx != -1) {
      _tables[idx] = _tables[idx].copyWith(
        status: M4TableStatus.available,
        currentCustomerName: null,
      );
      notifyListeners();
    }
  }

  /// Get live available tables count for restaurant
  int getAvailableTablesCount(String restaurantId) {
    return _tables.where((t) => t.status == M4TableStatus.available).length;
  }

  // ─── Capacity-Fit Next Party Suggestion ─────────────────────────────────────
  /// Automatically finds the best waiting party from queue to seat at given table
  M4QueueTicket? suggestNextPartyForTable(String tableId, String restaurantId) {
    final table = _tables.firstWhere((t) => t.id == tableId, orElse: () => _tables.first);
    if (!table.isAvailable) return null;

    final waiting = getActiveQueue(restaurantId);
    // Find parties that fit within capacity, prioritized by exact fit and queue position
    final fitting = waiting.where((t) => table.canFitParty(t.partySize)).toList();
    if (fitting.isEmpty) return null;

    // Sort by best capacity match first, then position
    fitting.sort((a, b) {
      final scoreA = table.fitScore(a.partySize);
      final scoreB = table.fitScore(b.partySize);
      if (scoreA != scoreB) return scoreA.compareTo(scoreB);
      return a.position.compareTo(b.position);
    });

    return fitting.first;
  }

  // ─── Dynamic Wait Time Calculation ──────────────────────────────────────────
  int calculateDynamicWaitTime(String restaurantId, int partySize) {
    final activeQueue = getActiveQueue(restaurantId);
    final partiesAhead = activeQueue.where((t) => t.partySize <= partySize + 2).length;

    // Self-learning turnover pacing:
    // 2-person party average dining: 35 mins
    // 4-person: 50 mins
    // 6+ person: 75 mins
    int baseMinutesPerParty;
    if (partySize <= 2) {
      baseMinutesPerParty = 6;
    } else if (partySize <= 4) {
      baseMinutesPerParty = 9;
    } else {
      baseMinutesPerParty = 14;
    }

    // Number of active matching available tables reduces wait time
    final availableFittingTables = _tables.where((tbl) => tbl.isAvailable && tbl.canFitParty(partySize)).length;
    final waitDeduction = availableFittingTables * 4;

    final totalMinutes = (partiesAhead * baseMinutesPerParty) - waitDeduction;
    return totalMinutes < 5 ? 5 : totalMinutes;
  }

  // ─── Position & Alert Recalculations ────────────────────────────────────────
  void _recalculatePositions(String restaurantId) {
    final active = _tickets
        .where((t) => t.restaurantId == restaurantId && t.isActive)
        .toList();

    // Priority tickets first, then by joinedAt
    active.sort((a, b) {
      if (a.isPriority && !b.isPriority) return -1;
      if (!a.isPriority && b.isPriority) return 1;
      return a.joinedAt.compareTo(b.joinedAt);
    });

    for (int i = 0; i < active.length; i++) {
      final t = active[i];
      final newPos = i + 1;
      final newEstWait = (newPos * 7).clamp(3, 120);

      // Trigger almost-your-turn alert if position is 2 or 1
      String newStatus = t.status;
      if (t.status == M4QueueStatus.waiting && newPos <= 2) {
        newStatus = M4QueueStatus.almostTurn;
      }

      final ticketIdx = _tickets.indexWhere((elem) => elem.id == t.id);
      if (ticketIdx != -1) {
        _tickets[ticketIdx] = t.copyWith(
          position: newPos,
          estimatedWaitMinutes: newEstWait,
          status: newStatus,
        );
      }
    }
  }

  // ─── Post-Visit Feedback ────────────────────────────────────────────────────
  void submitFeedback(String ticketId, int rating, String comments) {
    final idx = _tickets.indexWhere((t) => t.id == ticketId);
    if (idx != -1) {
      _tickets[idx] = _tickets[idx].copyWith(
        rating: rating,
        feedbackComments: comments,
      );
      notifyListeners();
    }
  }

  // ─── Queries ────────────────────────────────────────────────────────────────
  List<M4QueueTicket> getActiveQueue(String restaurantId) {
    return _tickets
        .where((t) => t.restaurantId == restaurantId && t.isActive)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  M4QueueTicket? getActiveCustomerTicket(String customerId, String restaurantId) {
    try {
      return _tickets.firstWhere(
        (t) => t.customerId == customerId && t.restaurantId == restaurantId && t.isActive,
      );
    } catch (_) {
      return null;
    }
  }

  M4QueueTicket? findTicketByNumber(String ticketNumber) {
    try {
      return _tickets.firstWhere((t) => t.ticketNumber.toUpperCase() == ticketNumber.toUpperCase().trim());
    } catch (_) {
      return null;
    }
  }
}
