import 'package:flutter/foundation.dart';
import 'package:dine_pulse/member_1/models/notification_model.dart';
import 'package:dine_pulse/core/constants/app_constants.dart';

/// Firebase-ready notification service for Member 1.
class NotificationService extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }

  Future<void> loadNotifications(String userId) async {
    _setLoading(true);
    try {
      // TODO: Firestore().collection('notifications').where('userId', isEqualTo: userId).orderBy('createdAt', descending: true).snapshots()
      await Future.delayed(const Duration(milliseconds: 600));
      _notifications = _mockNotifications(userId);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    _notifications = _notifications.map((n) {
      if (n.id == notificationId) return n.copyWith(isRead: true);
      return n;
    }).toList();
    // TODO: Firestore().collection('notifications').doc(notificationId).update({'isRead': true})
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    // TODO: batch update all notifications
    notifyListeners();
  }

  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    // TODO: Firestore().collection('notifications').doc(notificationId).delete()
    notifyListeners();
  }

  /// Add a real-time cross-module notification (from Member 2 reservation or Member 4 queue)
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  List<NotificationModel> _mockNotifications(String userId) => [
    NotificationModel(
      id: 'n1', userId: userId,
      title: 'Reservation Confirmed! 🎉',
      body: 'Your reservation at The Spice Garden for 4 people on Dec 15 at 7:00 PM has been confirmed.',
      type: AppConstants.notifReservation,
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      data: {'restaurantId': 'r1', 'reservationId': 'res1'},
    ),
    NotificationModel(
      id: 'n2', userId: userId,
      title: 'Reservation Reminder 🔔',
      body: 'Don\'t forget! You have a reservation at Sakura Japanese tomorrow at 6:30 PM.',
      type: AppConstants.notifReminder,
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      data: {'restaurantId': 'r2', 'reservationId': 'res2'},
    ),
    NotificationModel(
      id: 'n3', userId: userId,
      title: 'Special Offer – 20% Off! 🎊',
      body: 'Exclusive offer for DinePulse members at La Bella Italia. Use code DINE20 to get 20% off your next visit.',
      type: AppConstants.notifPromotion,
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      data: {'restaurantId': 'r3'},
    ),
    NotificationModel(
      id: 'n4', userId: userId,
      title: 'Reservation Cancelled',
      body: 'Your reservation at Dragon Palace for Dec 12 has been cancelled as requested.',
      type: AppConstants.notifReservation,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      data: {'restaurantId': 'r4', 'reservationId': 'res3'},
    ),
    NotificationModel(
      id: 'n5', userId: userId,
      title: 'New Restaurant Near You! 📍',
      body: 'Ocean Breeze Seafood just opened 0.5 km from your location. Check out their menu!',
      type: AppConstants.notifSystem,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      data: {'restaurantId': 'r5'},
    ),
    NotificationModel(
      id: 'n6', userId: userId,
      title: 'You\'ve been reviewed! ⭐',
      body: 'A restaurant responded to your review. Tap to see what they said.',
      type: AppConstants.notifSystem,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];
}
