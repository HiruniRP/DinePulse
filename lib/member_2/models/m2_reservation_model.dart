// Member 2 — Rich Reservation Model
class M2ReservationStatus {
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String rejected = 'rejected';
  static const String modified = 'modified';
  static const String cancelled = 'cancelled';
  static const String completed = 'completed';
  static const String noShow = 'no_show';
}

class M2TableStatus {
  static const String available = 'available';
  static const String reserved = 'reserved';
  static const String occupied = 'occupied';
  static const String cleaning = 'cleaning';
  static const String unavailable = 'unavailable';
}

class M2TableModel {
  final String id;
  final String number;
  final int capacity;
  final String location;
  final String status;
  final bool isAccessible;
  final bool hasWindowView;
  final String? currentReservationId;

  const M2TableModel({
    required this.id,
    required this.number,
    required this.capacity,
    required this.location,
    this.status = M2TableStatus.available,
    this.isAccessible = false,
    this.hasWindowView = false,
    this.currentReservationId,
  });

  bool get isAvailable => status == M2TableStatus.available;

  M2TableModel copyWith({String? status, String? currentReservationId}) {
    return M2TableModel(
      id: id,
      number: number,
      capacity: capacity,
      location: location,
      status: status ?? this.status,
      isAccessible: isAccessible,
      hasWindowView: hasWindowView,
      currentReservationId: currentReservationId ?? this.currentReservationId,
    );
  }

  factory M2TableModel.fromFirestore(Map<String, dynamic> data, String id) {
    return M2TableModel(
      id: id,
      number: data['number'] ?? '',
      capacity: data['capacity'] ?? 2,
      location: data['location'] ?? 'indoor',
      status: data['status'] ?? M2TableStatus.available,
      isAccessible: data['isAccessible'] ?? false,
      hasWindowView: data['hasWindowView'] ?? false,
      currentReservationId: data['currentReservationId'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'number': number,
    'capacity': capacity,
    'location': location,
    'status': status,
    'isAccessible': isAccessible,
    'hasWindowView': hasWindowView,
    'currentReservationId': currentReservationId,
  };
}

class M2PreOrderItem {
  final String menuItemId;
  final String menuItemName;
  final int quantity;
  final double unitPrice;
  final String? notes;

  const M2PreOrderItem({
    required this.menuItemId,
    required this.menuItemName,
    required this.quantity,
    required this.unitPrice,
    this.notes,
  });

  double get total => unitPrice * quantity;

  factory M2PreOrderItem.fromMap(Map<String, dynamic> data) {
    return M2PreOrderItem(
      menuItemId: data['menuItemId'] ?? '',
      menuItemName: data['menuItemName'] ?? '',
      quantity: data['quantity'] ?? 1,
      unitPrice: (data['unitPrice'] ?? 0.0).toDouble(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() => {
    'menuItemId': menuItemId,
    'menuItemName': menuItemName,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'notes': notes,
  };
}

class M2ModificationRecord {
  final String field;
  final String oldValue;
  final String newValue;
  final DateTime changedAt;
  final String changedBy;

  const M2ModificationRecord({
    required this.field,
    required this.oldValue,
    required this.newValue,
    required this.changedAt,
    required this.changedBy,
  });

  factory M2ModificationRecord.fromMap(Map<String, dynamic> data) {
    return M2ModificationRecord(
      field: data['field'] ?? '',
      oldValue: data['oldValue'] ?? '',
      newValue: data['newValue'] ?? '',
      changedAt: DateTime.tryParse(data['changedAt'] ?? '') ?? DateTime.now(),
      changedBy: data['changedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'field': field,
    'oldValue': oldValue,
    'newValue': newValue,
    'changedAt': changedAt.toIso8601String(),
    'changedBy': changedBy,
  };
}

class M2AuditEntry {
  final String action;
  final String actorId;
  final String actorName;
  final String actorRole;
  final DateTime timestamp;
  final String? notes;

  const M2AuditEntry({
    required this.action,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.timestamp,
    this.notes,
  });

  factory M2AuditEntry.fromMap(Map<String, dynamic> data) {
    return M2AuditEntry(
      action: data['action'] ?? '',
      actorId: data['actorId'] ?? '',
      actorName: data['actorName'] ?? '',
      actorRole: data['actorRole'] ?? 'customer',
      timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() => {
    'action': action,
    'actorId': actorId,
    'actorName': actorName,
    'actorRole': actorRole,
    'timestamp': timestamp.toIso8601String(),
    'notes': notes,
  };
}

class M2ReservationModel {
  final String id;
  final String bookingId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String restaurantId;
  final String restaurantName;
  final String restaurantImage;
  final DateTime date;
  final String time;
  final int partySize;
  final String? preferredTableId;
  final String? preferredTableNumber;
  final String? assignedTableId;
  final String? assignedTableNumber;
  final String tableLocation;
  final String status;
  final String? specialRequests;
  final String? specialOccasion;
  final bool isRecurring;
  final String? recurringPattern;
  final int? recurringCount;
  final List<M2PreOrderItem> preOrderItems;
  final bool depositRequired;
  final double? depositAmount;
  final bool depositPaid;
  final bool smsReminder;
  final bool emailReminder;
  final int reminderMinutes;
  final String? cancellationReason;
  final bool cancellationPolicyAccepted;
  final String? shiftNotes;
  final String? staffId;
  final String? staffName;
  final List<M2ModificationRecord> modificationHistory;
  final List<M2AuditEntry> auditTrail;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const M2ReservationModel({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantImage = '',
    required this.date,
    required this.time,
    required this.partySize,
    this.preferredTableId,
    this.preferredTableNumber,
    this.assignedTableId,
    this.assignedTableNumber,
    this.tableLocation = 'any',
    this.status = M2ReservationStatus.pending,
    this.specialRequests,
    this.specialOccasion,
    this.isRecurring = false,
    this.recurringPattern,
    this.recurringCount,
    this.preOrderItems = const [],
    this.depositRequired = false,
    this.depositAmount,
    this.depositPaid = false,
    this.smsReminder = true,
    this.emailReminder = true,
    this.reminderMinutes = 60,
    this.cancellationReason,
    this.cancellationPolicyAccepted = false,
    this.shiftNotes,
    this.staffId,
    this.staffName,
    this.modificationHistory = const [],
    this.auditTrail = const [],
    required this.createdAt,
    this.updatedAt,
  });

  bool get canCancel =>
      status == M2ReservationStatus.pending ||
      status == M2ReservationStatus.confirmed;

  bool get canModify =>
      status == M2ReservationStatus.pending ||
      status == M2ReservationStatus.confirmed;

  bool get isUpcoming => date.isAfter(DateTime.now()) && canCancel;

  double get preOrderTotal =>
      preOrderItems.fold(0.0, (sum, item) => sum + item.total);

  String get displayStatus {
    switch (status) {
      case M2ReservationStatus.pending: return 'Pending';
      case M2ReservationStatus.confirmed: return 'Confirmed';
      case M2ReservationStatus.rejected: return 'Rejected';
      case M2ReservationStatus.modified: return 'Modified';
      case M2ReservationStatus.cancelled: return 'Cancelled';
      case M2ReservationStatus.completed: return 'Completed';
      case M2ReservationStatus.noShow: return 'No Show';
      default: return status;
    }
  }

  factory M2ReservationModel.fromFirestore(Map<String, dynamic> data, String id) {
    return M2ReservationModel(
      id: id,
      bookingId: data['bookingId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      restaurantImage: data['restaurantImage'] ?? '',
      date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
      time: data['time'] ?? '',
      partySize: data['partySize'] ?? 1,
      preferredTableId: data['preferredTableId'],
      preferredTableNumber: data['preferredTableNumber'],
      assignedTableId: data['assignedTableId'],
      assignedTableNumber: data['assignedTableNumber'],
      tableLocation: data['tableLocation'] ?? 'any',
      status: data['status'] ?? M2ReservationStatus.pending,
      specialRequests: data['specialRequests'],
      specialOccasion: data['specialOccasion'],
      isRecurring: data['isRecurring'] ?? false,
      recurringPattern: data['recurringPattern'],
      recurringCount: data['recurringCount'],
      preOrderItems: (data['preOrderItems'] as List<dynamic>? ?? [])
          .map((e) => M2PreOrderItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      depositRequired: data['depositRequired'] ?? false,
      depositAmount: data['depositAmount']?.toDouble(),
      depositPaid: data['depositPaid'] ?? false,
      smsReminder: data['smsReminder'] ?? true,
      emailReminder: data['emailReminder'] ?? true,
      reminderMinutes: data['reminderMinutes'] ?? 60,
      cancellationReason: data['cancellationReason'],
      cancellationPolicyAccepted: data['cancellationPolicyAccepted'] ?? false,
      shiftNotes: data['shiftNotes'],
      staffId: data['staffId'],
      staffName: data['staffName'],
      modificationHistory: (data['modificationHistory'] as List<dynamic>? ?? [])
          .map((e) => M2ModificationRecord.fromMap(e as Map<String, dynamic>))
          .toList(),
      auditTrail: (data['auditTrail'] as List<dynamic>? ?? [])
          .map((e) => M2AuditEntry.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: data['updatedAt'] != null ? DateTime.tryParse(data['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'bookingId': bookingId,
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'customerEmail': customerEmail,
    'restaurantId': restaurantId,
    'restaurantName': restaurantName,
    'restaurantImage': restaurantImage,
    'date': date.toIso8601String(),
    'time': time,
    'partySize': partySize,
    'preferredTableId': preferredTableId,
    'preferredTableNumber': preferredTableNumber,
    'assignedTableId': assignedTableId,
    'assignedTableNumber': assignedTableNumber,
    'tableLocation': tableLocation,
    'status': status,
    'specialRequests': specialRequests,
    'specialOccasion': specialOccasion,
    'isRecurring': isRecurring,
    'recurringPattern': recurringPattern,
    'recurringCount': recurringCount,
    'preOrderItems': preOrderItems.map((e) => e.toMap()).toList(),
    'depositRequired': depositRequired,
    'depositAmount': depositAmount,
    'depositPaid': depositPaid,
    'smsReminder': smsReminder,
    'emailReminder': emailReminder,
    'reminderMinutes': reminderMinutes,
    'cancellationReason': cancellationReason,
    'cancellationPolicyAccepted': cancellationPolicyAccepted,
    'shiftNotes': shiftNotes,
    'staffId': staffId,
    'staffName': staffName,
    'modificationHistory': modificationHistory.map((e) => e.toMap()).toList(),
    'auditTrail': auditTrail.map((e) => e.toMap()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': DateTime.now().toIso8601String(),
  };

  M2ReservationModel copyWith({
    String? status,
    String? assignedTableId,
    String? assignedTableNumber,
    String? shiftNotes,
    String? staffId,
    String? staffName,
    String? cancellationReason,
    bool? depositPaid,
    List<M2ModificationRecord>? modificationHistory,
    List<M2AuditEntry>? auditTrail,
    DateTime? date,
    String? time,
    int? partySize,
    String? specialRequests,
    String? specialOccasion,
    String? tableLocation,
  }) {
    return M2ReservationModel(
      id: id,
      bookingId: bookingId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      restaurantImage: restaurantImage,
      date: date ?? this.date,
      time: time ?? this.time,
      partySize: partySize ?? this.partySize,
      preferredTableId: preferredTableId,
      preferredTableNumber: preferredTableNumber,
      assignedTableId: assignedTableId ?? this.assignedTableId,
      assignedTableNumber: assignedTableNumber ?? this.assignedTableNumber,
      tableLocation: tableLocation ?? this.tableLocation,
      status: status ?? this.status,
      specialRequests: specialRequests ?? this.specialRequests,
      specialOccasion: specialOccasion ?? this.specialOccasion,
      isRecurring: isRecurring,
      recurringPattern: recurringPattern,
      recurringCount: recurringCount,
      preOrderItems: preOrderItems,
      depositRequired: depositRequired,
      depositAmount: depositAmount,
      depositPaid: depositPaid ?? this.depositPaid,
      smsReminder: smsReminder,
      emailReminder: emailReminder,
      reminderMinutes: reminderMinutes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancellationPolicyAccepted: cancellationPolicyAccepted,
      shiftNotes: shiftNotes ?? this.shiftNotes,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      modificationHistory: modificationHistory ?? this.modificationHistory,
      auditTrail: auditTrail ?? this.auditTrail,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
