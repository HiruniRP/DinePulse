import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dine_pulse/shared/models/shared_restaurant_model.dart';
import 'package:dine_pulse/shared/services/firestore_collections.dart';
import 'package:dine_pulse/shared/services/table_repository.dart';
import 'package:dine_pulse/shared/services/queue_repository.dart';

/// Restaurant Discovery Service for Member 1
/// Automatically enriches restaurant items with Member 4's live wait time,
/// active queue length, and table availability status.
class SharedRestaurantDiscoveryService {
  FirebaseFirestore? _firestore;
  final SharedTableRepository tableRepo;
  final SharedQueueRepository queueRepo;

  // In-memory fallback restaurants
  final List<SharedRestaurantModel> _mockRestaurants = [];

  SharedRestaurantDiscoveryService({
    required this.tableRepo,
    required this.queueRepo,
  }) {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestore = FirebaseFirestore.instance;
      }
    } catch (e) {
      debugPrint('Firestore initialization notice: $e');
    }
    _seedMockRestaurants();
  }

  void _seedMockRestaurants() {
    _mockRestaurants.addAll([
      const SharedRestaurantModel(
        id: 'rest1',
        name: 'The Grand Heritage',
        description: 'Fine dining Sri Lankan and international culinary experience.',
        cuisine: 'Sri Lankan Fusion',
        address: '12 Galle Face Terrace',
        city: 'Colombo 03',
        rating: 4.8,
        reviewCount: 342,
        priceRange: r'$$$',
        imageUrls: [
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80',
        ],
        isOpen: true,
        currentWaitMinutes: 15,
        activeQueueLength: 3,
        totalTables: 8,
        availableTablesCount: 4,
      ),
      const SharedRestaurantModel(
        id: 'rest2',
        name: 'Ocean Breeze Seafood',
        description: 'Fresh seafood catches prepared daily along the coastal breeze.',
        cuisine: 'Seafood',
        address: '45 Marine Drive',
        city: 'Colombo 04',
        rating: 4.6,
        reviewCount: 198,
        priceRange: r'$$',
        imageUrls: [
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80',
        ],
        isOpen: true,
        currentWaitMinutes: 5,
        activeQueueLength: 1,
        totalTables: 6,
        availableTablesCount: 3,
      ),
      const SharedRestaurantModel(
        id: 'rest3',
        name: 'Little Italy Trattoria',
        description: 'Authentic woodfired pizzas and handmade artisanal pastas.',
        cuisine: 'Italian',
        address: '88 Park Road',
        city: 'Colombo 05',
        rating: 4.7,
        reviewCount: 260,
        priceRange: r'$$',
        imageUrls: [
          'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=800&q=80',
        ],
        isOpen: false, // Closed status
        currentWaitMinutes: 0,
        activeQueueLength: 0,
        totalTables: 5,
        availableTablesCount: 0,
      ),
    ]);
  }

  // ─── Rule 4: Show Restaurant Live Wait Time, Queue Length & Status ─────────
  Stream<List<SharedRestaurantModel>> streamDiscoveryRestaurants() {
    if (_firestore != null) {
      return _firestore!
          .collection(FirestoreCollections.restaurants)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => SharedRestaurantModel.fromFirestore(doc.data(), doc.id))
              .toList());
    }

    return Stream.value(_mockRestaurants);
  }

  /// Calculates up-to-the-minute live wait time & queue metrics for a restaurant
  Future<SharedRestaurantModel> getEnrichedRestaurantDetails(String restaurantId) async {
    SharedRestaurantModel base;
    try {
      base = _mockRestaurants.firstWhere((r) => r.id == restaurantId);
    } catch (_) {
      base = const SharedRestaurantModel(
        id: 'unknown',
        name: 'Restaurant',
        description: '',
        cuisine: '',
        address: '',
        city: '',
      );
    }

    // Pull live metrics from Member 4 Queue & Table repos
    final dynamicWait = await queueRepo.calculateDynamicWaitTime(
      restaurantId: restaurantId,
      partySize: 2,
    );
    final availableTables = await tableRepo.getAvailableTablesCount(restaurantId);

    return base.copyWith(
      currentWaitMinutes: dynamicWait,
      availableTablesCount: availableTables,
    );
  }
}
