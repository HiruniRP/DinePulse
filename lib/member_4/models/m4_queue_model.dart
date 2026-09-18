// Member 4: Virtual Queue & Table Management Data Models

/// Queue Ticket Statuses
class M4QueueStatus {
  static const String waiting = 'waiting';
  static const String almostTurn = 'almost_turn';
  static const String called = 'called';
  static const String seated = 'seated';
  static const String cancelled = 'cancelled';
  static const String noShow = 'no_show';
  static const String expired = 'expired';
}

/// Table Statuses for Member 4 Table Management
class M4TableStatus {
  static const String available = 'available';
  static const String occupied = 'occupied';
  static const String reservedM2 = 'reserved_m2'; // Synchronized from Member 2 reservations
  static const String cleaning = 'cleaning';
  static const String maintenance = 'maintenance';
}

/// Notification Channels
class M4NotificationChannel {
  static const String push = 'Push Notification';
  static const String sms = 'SMS Text';
  static const String whatsapp = 'WhatsApp';
}

/// Supported UI Languages
enum M4Language {
  english,
  sinhala,
  tamil,
}

/// Audit log entry for queue lifecycle tracking
class M4QueueAuditEntry {
  final String action;
  final DateTime timestamp;
  final String actor;
  final String? notes;

  const M4QueueAuditEntry({
    required this.action,
    required this.timestamp,
    required this.actor,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'action': action,
    'timestamp': timestamp.toIso8601String(),
    'actor': actor,
    'notes': notes,
  };

  factory M4QueueAuditEntry.fromMap(Map<String, dynamic> map) {
    return M4QueueAuditEntry(
      action: map['action'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      actor: map['actor'] ?? 'system',
      notes: map['notes'],
    );
  }
}

/// Queue Ticket Model
class M4QueueTicket {
  final String id;
  final String ticketNumber; // e.g. "Q-101"
  final String restaurantId;
  final String restaurantName;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final int partySize;
  final String seatingPreference; // 'Any', 'Indoor', 'Outdoor', 'Booth'
  final bool needsHighChair;
  final bool needsWheelchair;
  final bool prefersQuietCorner;
  final String? specialNotes;
  final String notificationChannel;
  final String status; // M4QueueStatus
  final int position; // 1-based index in queue
  final int initialWaitMinutes;
  final int estimatedWaitMinutes;
  final DateTime joinedAt;
  final DateTime? calledAt;
  final int callCountdownSeconds; // remaining seconds when called (e.g. 300s / 5 mins)
  final DateTime? seatedAt;
  final String? assignedTableId;
  final String? assignedTableNumber;
  final bool isWalkIn;
  final int delayMinutesAlert; // e.g. +10 mins delay alert
  final String? staffNotes;
  final bool isPriority;
  final List<M4QueueAuditEntry> auditTrail;
  final int? rating;
  final String? feedbackComments;
  final bool waitElsewhereActive;
  final double waitElsewhereRadiusMeters;

  const M4QueueTicket({
    required this.id,
    required this.ticketNumber,
    required this.restaurantId,
    required this.restaurantName,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.partySize,
    this.seatingPreference = 'Any',
    this.needsHighChair = false,
    this.needsWheelchair = false,
    this.prefersQuietCorner = false,
    this.specialNotes,
    this.notificationChannel = M4NotificationChannel.push,
    this.status = M4QueueStatus.waiting,
    required this.position,
    required this.initialWaitMinutes,
    required this.estimatedWaitMinutes,
    required this.joinedAt,
    this.calledAt,
    this.callCountdownSeconds = 300,
    this.seatedAt,
    this.assignedTableId,
    this.assignedTableNumber,
    this.isWalkIn = false,
    this.delayMinutesAlert = 0,
    this.staffNotes,
    this.isPriority = false,
    this.auditTrail = const [],
    this.rating,
    this.feedbackComments,
    this.waitElsewhereActive = false,
    this.waitElsewhereRadiusMeters = 500,
  });

  bool get isActive =>
      status == M4QueueStatus.waiting ||
      status == M4QueueStatus.almostTurn ||
      status == M4QueueStatus.called;

  bool get isCalled => status == M4QueueStatus.called;
  bool get isAlmostTurn => status == M4QueueStatus.almostTurn;

  /// Privacy-safe masked name for public queue displays
  String get maskedCustomerName {
    final parts = customerName.trim().split(' ');
    if (parts.isEmpty || customerName.isEmpty) return 'Guest';
    if (parts.length == 1) {
      final name = parts[0];
      if (name.length <= 2) return name;
      return '${name[0]}***${name[name.length - 1]}';
    }
    return '${parts[0]} ${parts.last[0]}.';
  }

  String get displayStatus {
    switch (status) {
      case M4QueueStatus.waiting:
        return 'Waiting in Queue';
      case M4QueueStatus.almostTurn:
        return 'Almost Your Turn!';
      case M4QueueStatus.called:
        return 'Table Ready (Head to Host)';
      case M4QueueStatus.seated:
        return 'Seated';
      case M4QueueStatus.cancelled:
        return 'Cancelled';
      case M4QueueStatus.noShow:
        return 'No Show';
      case M4QueueStatus.expired:
        return 'Expired';
      default:
        return status;
    }
  }

  M4QueueTicket copyWith({
    String? status,
    int? position,
    int? estimatedWaitMinutes,
    DateTime? calledAt,
    int? callCountdownSeconds,
    DateTime? seatedAt,
    String? assignedTableId,
    String? assignedTableNumber,
    int? delayMinutesAlert,
    String? staffNotes,
    bool? isPriority,
    List<M4QueueAuditEntry>? auditTrail,
    int? rating,
    String? feedbackComments,
    bool? waitElsewhereActive,
    double? waitElsewhereRadiusMeters,
  }) {
    return M4QueueTicket(
      id: id,
      ticketNumber: ticketNumber,
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
      status: status ?? this.status,
      position: position ?? this.position,
      initialWaitMinutes: initialWaitMinutes,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      joinedAt: joinedAt,
      calledAt: calledAt ?? this.calledAt,
      callCountdownSeconds: callCountdownSeconds ?? this.callCountdownSeconds,
      seatedAt: seatedAt ?? this.seatedAt,
      assignedTableId: assignedTableId ?? this.assignedTableId,
      assignedTableNumber: assignedTableNumber ?? this.assignedTableNumber,
      isWalkIn: isWalkIn,
      delayMinutesAlert: delayMinutesAlert ?? this.delayMinutesAlert,
      staffNotes: staffNotes ?? this.staffNotes,
      isPriority: isPriority ?? this.isPriority,
      auditTrail: auditTrail ?? this.auditTrail,
      rating: rating ?? this.rating,
      feedbackComments: feedbackComments ?? this.feedbackComments,
      waitElsewhereActive: waitElsewhereActive ?? this.waitElsewhereActive,
      waitElsewhereRadiusMeters: waitElsewhereRadiusMeters ?? this.waitElsewhereRadiusMeters,
    );
  }
}

/// Member 4 Table Management Model
class M4TableItem {
  final String id;
  final String number;
  final int capacity;
  final String location; // 'Indoor', 'Outdoor', 'Booth', 'Bar'
  final String status; // M4TableStatus
  final String? currentQueueTicketId;
  final String? currentCustomerName;
  final DateTime? seatedTime;
  final int cleaningDurationSeconds; // e.g. 180s cleaning timer
  final DateTime? cleaningStartedAt;

  const M4TableItem({
    required this.id,
    required this.number,
    required this.capacity,
    required this.location,
    this.status = M4TableStatus.available,
    this.currentQueueTicketId,
    this.currentCustomerName,
    this.seatedTime,
    this.cleaningDurationSeconds = 180,
    this.cleaningStartedAt,
  });

  bool get isAvailable => status == M4TableStatus.available;
  bool get isOccupied => status == M4TableStatus.occupied;
  bool get isCleaning => status == M4TableStatus.cleaning;
  bool get isReservedM2 => status == M4TableStatus.reservedM2;

  /// Check capacity suitability (e.g. party fits without taking table too large)
  bool canFitParty(int partySize) {
    if (!isAvailable) return false;
    return capacity >= partySize;
  }

  /// Fit score: how closely capacity matches party size (0 is exact match, higher is less optimal)
  int fitScore(int partySize) {
    if (capacity < partySize) return 999;
    return capacity - partySize;
  }

  M4TableItem copyWith({
    String? status,
    String? currentQueueTicketId,
    String? currentCustomerName,
    DateTime? seatedTime,
    DateTime? cleaningStartedAt,
  }) {
    return M4TableItem(
      id: id,
      number: number,
      capacity: capacity,
      location: location,
      status: status ?? this.status,
      currentQueueTicketId: currentQueueTicketId ?? this.currentQueueTicketId,
      currentCustomerName: currentCustomerName ?? this.currentCustomerName,
      seatedTime: seatedTime ?? this.seatedTime,
      cleaningDurationSeconds: cleaningDurationSeconds,
      cleaningStartedAt: cleaningStartedAt ?? this.cleaningStartedAt,
    );
  }
}

/// Queue Configuration & Status
class M4QueueConfig {
  final bool isQueueOpen;
  final String? pauseReason;
  final int baseWaitPerPartyMinutes;
  final String peakPredictionMessage;

  const M4QueueConfig({
    this.isQueueOpen = true,
    this.pauseReason,
    this.baseWaitPerPartyMinutes = 8,
    this.peakPredictionMessage = 'High volume expected around 7:30 PM (+15m wait)',
  });

  M4QueueConfig copyWith({
    bool? isQueueOpen,
    String? pauseReason,
    int? baseWaitPerPartyMinutes,
    String? peakPredictionMessage,
  }) {
    return M4QueueConfig(
      isQueueOpen: isQueueOpen ?? this.isQueueOpen,
      pauseReason: pauseReason ?? this.pauseReason,
      baseWaitPerPartyMinutes: baseWaitPerPartyMinutes ?? this.baseWaitPerPartyMinutes,
      peakPredictionMessage: peakPredictionMessage ?? this.peakPredictionMessage,
    );
  }
}

/// Localization dictionary for English, Sinhala, and Tamil
class M4Localizations {
  static const Map<String, Map<M4Language, String>> strings = {
    'join_queue': {
      M4Language.english: 'Join Virtual Queue',
      M4Language.sinhala: 'පෝලිමට එක්වන්න',
      M4Language.tamil: 'வரிசையில் சேரவும்',
    },
    'live_ticket': {
      M4Language.english: 'Your Queue Ticket',
      M4Language.sinhala: 'ඔබේ පෝලිම් ටිකට්පත',
      M4Language.tamil: 'உங்கள் டோக்கன்',
    },
    'position_in_line': {
      M4Language.english: 'Position in Line',
      M4Language.sinhala: 'පෝලිමේ ඔබගේ ස්ථානය',
      M4Language.tamil: 'வரிசை எண்',
    },
    'est_wait': {
      M4Language.english: 'Estimated Wait',
      M4Language.sinhala: 'ඇස්තමේන්තුගත කාලය',
      M4Language.tamil: 'எதிர்பார்க்கப்படும் நேரம்',
    },
    'table_ready': {
      M4Language.english: 'Your Table is Ready!',
      M4Language.sinhala: 'ඔබේ මේසය සූදානම්!',
      M4Language.tamil: 'உங்கள் மேஜை தயார்!',
    },
    'almost_turn': {
      M4Language.english: 'Almost your turn! Please stay near the entrance.',
      M4Language.sinhala: 'ඉක්මනින් ඔබේ වාරයයි! කරුණාකර දොරටුව අසල රැඳෙන්න.',
      M4Language.tamil: 'உங்கள் முறை வரப்போகிறது! நுழைவாயில் அருகில் இருங்கள்.',
    },
    'leave_queue': {
      M4Language.english: 'Leave Queue',
      M4Language.sinhala: 'පෝලිමෙන් ඉවත් වන්න',
      M4Language.tamil: 'வரிசையிலிருந்து வெளியேறு',
    },
    'wait_elsewhere': {
      M4Language.english: 'Wait-Elsewhere Mode',
      M4Language.sinhala: 'වෙනත් තැනක රැඳී සිටීමේ මාදිලිය',
      M4Language.tamil: 'வேறு இடத்தில் காத்திருப்பு பயன்முறை',
    },
  };

  static String tr(String key, M4Language lang) {
    return strings[key]?[lang] ?? strings[key]?[M4Language.english] ?? key;
  }
}
