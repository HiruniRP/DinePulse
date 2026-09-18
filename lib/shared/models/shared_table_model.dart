// Shared Table Model for DinePulse Firebase Backend

class SharedTableStatus {
  static const String available = 'available';
  static const String reserved = 'reserved'; // Reserved via Member 2
  static const String occupied = 'occupied';
  static const String cleaning = 'cleaning';
  static const String maintenance = 'maintenance';
}

class SharedTableModel {
  final String id;
  final String restaurantId;
  final String number;
  final int capacity;
  final String location; // 'Indoor', 'Outdoor', 'Window', 'Booth', 'Private', 'Bar'
  final String status; // SharedTableStatus
  final bool isAccessible;
  final bool hasWindowView;

  // Assignment synchronization
  final String? currentReservationId; // Synchronized from Member 2 reservation
  final String? currentQueueTicketId; // Synchronized from Member 4 queue ticket
  final String? currentCustomerName;
  final DateTime? seatedTime;
  final DateTime? cleaningStartedAt;
  final int cleaningDurationSeconds;
  final DateTime? updatedAt;

  const SharedTableModel({
    required this.id,
    required this.restaurantId,
    required this.number,
    required this.capacity,
    required this.location,
    this.status = SharedTableStatus.available,
    this.isAccessible = false,
    this.hasWindowView = false,
    this.currentReservationId,
    this.currentQueueTicketId,
    this.currentCustomerName,
    this.seatedTime,
    this.cleaningStartedAt,
    this.cleaningDurationSeconds = 180,
    this.updatedAt,
  });

  // Cross-member business rules
  bool get isAvailable => status == SharedTableStatus.available;
  bool get isReserved => status == SharedTableStatus.reserved;
  bool get isOccupied => status == SharedTableStatus.occupied;
  bool get isCleaning => status == SharedTableStatus.cleaning;

  /// CRITICAL RULE: Reserved, occupied, and cleaning tables CANNOT be assigned to queue customers
  bool get canAssignToQueue => isAvailable;

  /// Check capacity suitability
  bool canFitParty(int partySize) => isAvailable && capacity >= partySize;

  factory SharedTableModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SharedTableModel(
      id: id,
      restaurantId: data['restaurantId'] ?? '',
      number: data['number']?.toString() ?? '',
      capacity: (data['capacity'] as num?)?.toInt() ?? 2,
      location: data['location'] ?? 'Indoor',
      status: data['status'] ?? SharedTableStatus.available,
      isAccessible: data['isAccessible'] ?? false,
      hasWindowView: data['hasWindowView'] ?? false,
      currentReservationId: data['currentReservationId'],
      currentQueueTicketId: data['currentQueueTicketId'],
      currentCustomerName: data['currentCustomerName'],
      seatedTime: data['seatedTime'] != null
          ? (data['seatedTime'] is DateTime
              ? data['seatedTime'] as DateTime
              : DateTime.tryParse(data['seatedTime'].toString()))
          : null,
      cleaningStartedAt: data['cleaningStartedAt'] != null
          ? (data['cleaningStartedAt'] is DateTime
              ? data['cleaningStartedAt'] as DateTime
              : DateTime.tryParse(data['cleaningStartedAt'].toString()))
          : null,
      cleaningDurationSeconds: (data['cleaningDurationSeconds'] as num?)?.toInt() ?? 180,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] is DateTime
              ? data['updatedAt'] as DateTime
              : DateTime.tryParse(data['updatedAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'number': number,
      'capacity': capacity,
      'location': location,
      'status': status,
      'isAccessible': isAccessible,
      'hasWindowView': hasWindowView,
      'currentReservationId': currentReservationId,
      'currentQueueTicketId': currentQueueTicketId,
      'currentCustomerName': currentCustomerName,
      'seatedTime': seatedTime?.toIso8601String(),
      'cleaningStartedAt': cleaningStartedAt?.toIso8601String(),
      'cleaningDurationSeconds': cleaningDurationSeconds,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  SharedTableModel copyWith({
    String? status,
    String? currentReservationId,
    String? currentQueueTicketId,
    String? currentCustomerName,
    DateTime? seatedTime,
    DateTime? cleaningStartedAt,
    DateTime? updatedAt,
  }) {
    return SharedTableModel(
      id: id,
      restaurantId: restaurantId,
      number: number,
      capacity: capacity,
      location: location,
      status: status ?? this.status,
      isAccessible: isAccessible,
      hasWindowView: hasWindowView,
      currentReservationId: currentReservationId ?? this.currentReservationId,
      currentQueueTicketId: currentQueueTicketId ?? this.currentQueueTicketId,
      currentCustomerName: currentCustomerName ?? this.currentCustomerName,
      seatedTime: seatedTime ?? this.seatedTime,
      cleaningStartedAt: cleaningStartedAt ?? this.cleaningStartedAt,
      cleaningDurationSeconds: cleaningDurationSeconds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
