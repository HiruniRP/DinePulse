// Shared Favourite Model for DinePulse Firebase Backend

class SharedFavouriteModel {
  final String userId;
  final String restaurantId;
  final DateTime createdAt;

  const SharedFavouriteModel({
    required this.userId,
    required this.restaurantId,
    required this.createdAt,
  });

  factory SharedFavouriteModel.fromFirestore(Map<String, dynamic> data) {
    return SharedFavouriteModel(
      userId: data['userId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is DateTime
              ? data['createdAt'] as DateTime
              : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'restaurantId': restaurantId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
