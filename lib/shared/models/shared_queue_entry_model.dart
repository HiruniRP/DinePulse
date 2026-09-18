// Shared Queue Entry Model for DinePulse Firebase Backend

class SharedQueueStatus {
  static const String waiting = 'waiting';
  static const String almostTurn = 'almost_turn';
  static const String called = 'called';
  static const String seated = 'seated';
  static const String cancelled = 'cancelled';
  static const String noShow = 'no_show';
  static const String expired = 'expired';
}

class SharedQueueEntryModel {
  final String id;
  final String ticketNumber; // e.g. "Q-101"
  final String restaurantId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final int partySize;
  final String seatingPreference; // 'Any', 'Indoor', 'Outdoor', 'Booth'
  final int position;
  final String status; // SharedQueueStatus
  final int initialWaitMinutes;
  final int estimatedWaitMinutes;
  final DateTime joinedAt;
  final DateTime? calledAt;
  final DateTime? seatedAt;
  final String? assignedTableId;
  final String? assignedTableNumber;
  final bool isWalkIn;
  final String? staffNotes;

  const SharedQueueEntryModel({
    required this.id,
    required this.ticketNumber,
    required this.restaurantId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.partySize,
    this.seatingPreference = 'Any',
    required this.position,
    this.status = SharedQueueStatus.waiting,
    required this.initialWaitMinutes,
    required this.estimatedWaitMinutes,
    required this.joinedAt,
    this.calledAt,
    this.seatedAt,
    this.assignedTableId,
    this.assignedTableNumber,
    this.isWalkIn = false,
    this.staffNotes,
  });

  bool get isActive =>
      status == SharedQueueStatus.waiting ||
      status == SharedQueueStatus.almostTurn ||
      status == SharedQueueStatus.called;

  bool get isCalled => status == SharedQueueStatus.called;

  factory SharedQueueEntryModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SharedQueueEntryModel(
      id: id,
      ticketNumber: data['ticketNumber'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      partySize: (data['partySize'] as num?)?.toInt() ?? 2,
      seatingPreference: data['seatingPreference'] ?? 'Any',
      position: (data['position'] as num?)?.toInt() ?? 1,
      status: data['status'] ?? SharedQueueStatus.waiting,
      initialWaitMinutes: (data['initialWaitMinutes'] as num?)?.toInt() ?? 15,
      estimatedWaitMinutes: (data['estimatedWaitMinutes'] as num?)?.toInt() ?? 15,
      joinedAt: data['joinedAt'] != null
          ? (data['joinedAt'] is DateTime
              ? data['joinedAt'] as DateTime
              : DateTime.tryParse(data['joinedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      calledAt: data['calledAt'] != null
          ? (data['calledAt'] is DateTime
              ? data['calledAt'] as DateTime
              : DateTime.tryParse(data['calledAt'].toString()))
          : null,
      seatedAt: data['seatedAt'] != null
          ? (data['seatedAt'] is DateTime
              ? data['seatedAt'] as DateTime
              : DateTime.tryParse(data['seatedAt'].toString()))
          : null,
      assignedTableId: data['assignedTableId'],
      assignedTableNumber: data['assignedTableNumber']?.toString(),
      isWalkIn: data['isWalkIn'] ?? false,
      staffNotes: data['staffNotes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ticketNumber': ticketNumber,
      'restaurantId': restaurantId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'partySize': partySize,
      'seatingPreference': seatingPreference,
      'position': position,
      'status': status,
      'initialWaitMinutes': initialWaitMinutes,
      'estimatedWaitMinutes': estimatedWaitMinutes,
      'joinedAt': joinedAt.toIso8601String(),
      'calledAt': calledAt?.toIso8601String(),
      'seatedAt': seatedAt?.toIso8601String(),
      'assignedTableId': assignedTableId,
      'assignedTableNumber': assignedTableNumber,
      'isWalkIn': isWalkIn,
      'staffNotes': staffNotes,
    };
  }

  SharedQueueEntryModel copyWith({
    String? id,
    int? position,
    String? status,
    int? estimatedWaitMinutes,
    DateTime? calledAt,
    DateTime? seatedAt,
    String? assignedTableId,
    String? assignedTableNumber,
    String? staffNotes,
  }) {
    return SharedQueueEntryModel(
      id: id ?? this.id,
      ticketNumber: ticketNumber,
      restaurantId: restaurantId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      partySize: partySize,
      seatingPreference: seatingPreference,
      position: position ?? this.position,
      status: status ?? this.status,
      initialWaitMinutes: initialWaitMinutes,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      joinedAt: joinedAt,
      calledAt: calledAt ?? this.calledAt,
      seatedAt: seatedAt ?? this.seatedAt,
      assignedTableId: assignedTableId ?? this.assignedTableId,
      assignedTableNumber: assignedTableNumber ?? this.assignedTableNumber,
      isWalkIn: isWalkIn,
      staffNotes: staffNotes ?? this.staffNotes,
    );
  }
}
