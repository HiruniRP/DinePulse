import 'package:flutter/material.dart';
import 'package:dine_pulse/shared/services/firebase_auth_service.dart';
import 'package:dine_pulse/shared/services/firebase_storage_service.dart';
import 'package:dine_pulse/shared/services/firebase_messaging_service.dart';
import 'package:dine_pulse/shared/services/table_repository.dart';
import 'package:dine_pulse/shared/services/reservation_repository.dart';
import 'package:dine_pulse/shared/services/queue_repository.dart';
import 'package:dine_pulse/shared/services/restaurant_discovery_service.dart';

/// Shared Firebase Provider coordinating all backend repositories and cross-module rules
class SharedFirebaseProvider extends ChangeNotifier {
  final SharedFirebaseAuthService authService;
  final SharedFirebaseStorageService storageService;
  final SharedFirebaseMessagingService messagingService;
  final SharedTableRepository tableRepository;
  final SharedReservationRepository reservationRepository;
  final SharedQueueRepository queueRepository;
  final SharedRestaurantDiscoveryService discoveryService;

  SharedFirebaseProvider._({
    required this.authService,
    required this.storageService,
    required this.messagingService,
    required this.tableRepository,
    required this.reservationRepository,
    required this.queueRepository,
    required this.discoveryService,
  });

  factory SharedFirebaseProvider.initialize() {
    final auth = SharedFirebaseAuthService();
    final storage = SharedFirebaseStorageService();
    final messaging = SharedFirebaseMessagingService();
    final tableRepo = SharedTableRepository();
    final resRepo = SharedReservationRepository(tableRepo: tableRepo);
    final queueRepo = SharedQueueRepository(tableRepo: tableRepo);
    final discovery = SharedRestaurantDiscoveryService(
      tableRepo: tableRepo,
      queueRepo: queueRepo,
    );

    return SharedFirebaseProvider._(
      authService: auth,
      storageService: storage,
      messagingService: messaging,
      tableRepository: tableRepo,
      reservationRepository: resRepo,
      queueRepository: queueRepo,
      discoveryService: discovery,
    );
  }
}
