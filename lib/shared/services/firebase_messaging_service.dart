import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Shared Firebase Cloud Messaging (FCM) Service
/// Manages device push tokens, notification permissions, and message reception.
class SharedFirebaseMessagingService {
  FirebaseMessaging? _fcm;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessage => _messageStreamController.stream;

  SharedFirebaseMessagingService() {
    _initFCM();
  }

  Future<void> _initFCM() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _fcm = FirebaseMessaging.instance;

        // Request user permissions
        final settings = await _fcm!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          _fcmToken = await _fcm!.getToken();
          debugPrint('FCM Device Token retrieved: $_fcmToken');
        }

        // Listen for foreground push notifications
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('FCM Foreground Message: ${message.notification?.title}');
          _messageStreamController.add(message);
        });

        // Token refresh listener
        _fcm!.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
        });
      } else {
        _fcmToken = 'mock_fcm_token_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      debugPrint('FCM initialization notice: $e (push notifications simulated)');
      _fcmToken = 'mock_fcm_token_offline';
    }
  }

  /// Subscribes to restaurant topic (e.g. for restaurant staff or customer wait-time alerts)
  Future<void> subscribeToRestaurantTopic(String restaurantId) async {
    try {
      if (_fcm != null) {
        await _fcm!.subscribeToTopic('restaurant_$restaurantId');
      }
    } catch (e) {
      debugPrint('Topic subscription notice: $e');
    }
  }

  /// Unsubscribes from restaurant topic
  Future<void> unsubscribeFromRestaurantTopic(String restaurantId) async {
    try {
      if (_fcm != null) {
        await _fcm!.unsubscribeFromTopic('restaurant_$restaurantId');
      }
    } catch (e) {
      debugPrint('Topic unsubscription notice: $e');
    }
  }
}
