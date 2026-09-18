// Shared Notification Model for DinePulse Firebase Backend

class SharedNotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // 'reservation_confirmed', 'table_ready', 'almost_turn', 'queue_update', 'reminder', 'system'
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const SharedNotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  factory SharedNotificationModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SharedNotificationModel(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'general',
      data: (data['data'] as Map<String, dynamic>?) ?? {},
      isRead: data['isRead'] ?? false,
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
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  SharedNotificationModel copyWith({bool? isRead}) {
    return SharedNotificationModel(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
