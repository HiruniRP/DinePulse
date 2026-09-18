// Shared Reservation Model for DinePulse Firebase Backend

class SharedReservationStatus {
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String rejected = 'rejected';
  static const String modified = 'modified';
  static const String cancelled = 'cancelled';
  static const String completed = 'completed';
  static const String noShow = 'no_show';
}

class SharedPreOrderItem {
  final String menuItemId;
  final String menuItemName;
  final int quantity;
  final double unitPrice;

  const SharedPreOrderItem({
    required this.menuItemId,
    required this.menuItemName,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => unitPrice * quantity;

  factory SharedPreOrderItem.fromMap(Map<String, dynamic> map) {
    return SharedPreOrderItem(
      menuItemId: map['menuItemId'] ?? '',
      menuItemName: map['menuItemName'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
    'menuItemId': menuItemId,
    'menuItemName': menuItemName,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };
}

class SharedReservationModel {
  final String id;
  final String bookingId; // e.g. "DP-83921"
  final String customerId; // Logged-in customer UID (Member 1 query filter)
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String restaurantId;
  final String restaurantName;
  final String? restaurantImage;
  final String? tableId; // Associated table (triggers table.status = reserved)
  final String? tableNumber;
  final DateTime date;
  final String timeSlot;
  final int partySize;
  final String status; // SharedReservationStatus
  final String? specialRequests;
  final String? specialOccasion;
  final double? depositAmount;
  final bool depositPaid;
  final List<SharedPreOrderItem> preOrderItems;
  final String? cancellationReason;
  final String? staffNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SharedReservationModel({
    required this.id,
    required this.bookingId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantImage,
    this.tableId,
    this.tableNumber,
    required this.date,
    required this.timeSlot,
    required this.partySize,
    this.status = SharedReservationStatus.pending,
    this.specialRequests,
    this.specialOccasion,
    this.depositAmount,
    this.depositPaid = false,
    this.preOrderItems = const [],
    this.cancellationReason,
    this.staffNotes,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isUpcoming =>
      date.isAfter(DateTime.now().subtract(const Duration(hours: 2))) &&
      (status == SharedReservationStatus.pending ||
          status == SharedReservationStatus.confirmed ||
          status == SharedReservationStatus.modified);

  bool get isCancelled => status == SharedReservationStatus.cancelled;
  bool get isCompleted => status == SharedReservationStatus.completed;

  factory SharedReservationModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SharedReservationModel(
      id: id,
      bookingId: data['bookingId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      restaurantImage: data['restaurantImage'],
      tableId: data['tableId'],
      tableNumber: data['tableNumber']?.toString(),
      date: data['date'] != null
          ? (data['date'] is DateTime
              ? data['date'] as DateTime
              : DateTime.tryParse(data['date'].toString()) ?? DateTime.now())
          : DateTime.now(),
      timeSlot: data['timeSlot'] ?? data['time'] ?? '19:00',
      partySize: (data['partySize'] as num?)?.toInt() ?? 2,
      status: data['status'] ?? SharedReservationStatus.pending,
      specialRequests: data['specialRequests'],
      specialOccasion: data['specialOccasion'],
      depositAmount: (data['depositAmount'] as num?)?.toDouble(),
      depositPaid: data['depositPaid'] ?? false,
      preOrderItems: (data['preOrderItems'] as List<dynamic>?)
              ?.map((item) => SharedPreOrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      cancellationReason: data['cancellationReason'],
      staffNotes: data['staffNotes'] ?? data['shiftNotes'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is DateTime
              ? data['createdAt'] as DateTime
              : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is DateTime
              ? data['updatedAt'] as DateTime
              : DateTime.tryParse(data['updatedAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'restaurantImage': restaurantImage,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'date': date.toIso8601String(),
      'timeSlot': timeSlot,
      'partySize': partySize,
      'status': status,
      'specialRequests': specialRequests,
      'specialOccasion': specialOccasion,
      'depositAmount': depositAmount,
      'depositPaid': depositPaid,
      'preOrderItems': preOrderItems.map((e) => e.toMap()).toList(),
      'cancellationReason': cancellationReason,
      'staffNotes': staffNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  SharedReservationModel copyWith({
    String? id,
    String? status,
    String? tableId,
    String? tableNumber,
    DateTime? date,
    String? timeSlot,
    int? partySize,
    String? cancellationReason,
    String? staffNotes,
    DateTime? updatedAt,
  }) {
    return SharedReservationModel(
      id: id ?? this.id,
      bookingId: bookingId,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      restaurantImage: restaurantImage,
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      partySize: partySize ?? this.partySize,
      status: status ?? this.status,
      specialRequests: specialRequests,
      specialOccasion: specialOccasion,
      depositAmount: depositAmount,
      depositPaid: depositPaid,
      preOrderItems: preOrderItems,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      staffNotes: staffNotes ?? this.staffNotes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
