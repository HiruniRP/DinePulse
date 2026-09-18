import 'package:dine_pulse/core/constants/app_constants.dart';

class ReservationModel {
  final String id;
  final String customerId;
  final String customerName;
  final String restaurantId;
  final String restaurantName;
  final String restaurantImage;
  final DateTime date;
  final String time;
  final int partySize;
  final String status; // pending, confirmed, cancelled, completed
  final String? specialRequests;
  final String? tableNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ReservationModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantImage = '',
    required this.date,
    required this.time,
    required this.partySize,
    this.status = AppConstants.statusPending,
    this.specialRequests,
    this.tableNumber,
    required this.createdAt,
    this.updatedAt,
  });

  bool get canCancel =>
      status == AppConstants.statusPending || status == AppConstants.statusConfirmed;

  bool get isUpcoming =>
      date.isAfter(DateTime.now()) &&
      (status == AppConstants.statusPending || status == AppConstants.statusConfirmed);

  factory ReservationModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ReservationModel(
      id: id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      restaurantImage: data['restaurantImage'] ?? '',
      date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
      time: data['time'] ?? '',
      partySize: data['partySize'] ?? 1,
      status: data['status'] ?? AppConstants.statusPending,
      specialRequests: data['specialRequests'],
      tableNumber: data['tableNumber'],
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: data['updatedAt'] != null ? DateTime.tryParse(data['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'customerId': customerId,
    'customerName': customerName,
    'restaurantId': restaurantId,
    'restaurantName': restaurantName,
    'restaurantImage': restaurantImage,
    'date': date.toIso8601String(),
    'time': time,
    'partySize': partySize,
    'status': status,
    'specialRequests': specialRequests,
    'tableNumber': tableNumber,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': DateTime.now().toIso8601String(),
  };

  ReservationModel copyWith({String? status, String? tableNumber}) {
    return ReservationModel(
      id: id,
      customerId: customerId,
      customerName: customerName,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      restaurantImage: restaurantImage,
      date: date,
      time: time,
      partySize: partySize,
      status: status ?? this.status,
      specialRequests: specialRequests,
      tableNumber: tableNumber ?? this.tableNumber,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
