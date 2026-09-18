import 'package:flutter/foundation.dart';
import 'package:dine_pulse/member_1/models/restaurant_model.dart';

/// Firebase-ready restaurant discovery service for Member 1.
class RestaurantService extends ChangeNotifier {
  List<RestaurantModel> _restaurants = [];
  List<RestaurantModel> _searchResults = [];
  RestaurantModel? _selectedRestaurant;
  bool _isLoading = false;
  String? _error;

  List<RestaurantModel> get restaurants => _restaurants;
  List<RestaurantModel> get searchResults => _searchResults;
  RestaurantModel? get selectedRestaurant => _selectedRestaurant;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }

  /// Load featured/nearby restaurants for home screen
  Future<void> loadRestaurants() async {
    _setLoading(true);
    try {
      // TODO: Firestore().collection('restaurants').get()
      await Future.delayed(const Duration(milliseconds: 800));
      _restaurants = _mockRestaurants();
      _error = null;
    } catch (e) {
      _error = 'Failed to load restaurants';
    } finally {
      _setLoading(false);
    }
  }

  /// Search restaurants by query and filters
  Future<void> searchRestaurants({
    required String query,
    String? cuisine,
    String? priceRange,
    double? minRating,
    double? maxDistance,
    String sortBy = 'Relevance',
  }) async {
    _setLoading(true);
    try {
      // TODO: Firestore query with where clauses and ordering
      await Future.delayed(const Duration(milliseconds: 600));
      var results = _mockRestaurants().where((r) {
        final matchesQuery = query.isEmpty ||
            r.name.toLowerCase().contains(query.toLowerCase()) ||
            r.cuisine.toLowerCase().contains(query.toLowerCase()) ||
            r.tags.any((t) => t.toLowerCase().contains(query.toLowerCase()));
        final matchesCuisine = cuisine == null || cuisine == 'All' ||
            r.cuisine.toLowerCase() == cuisine.toLowerCase();
        final matchesPrice = priceRange == null || priceRange == 'All' ||
            r.priceRange == priceRange.split(' ').first;
        final matchesRating = minRating == null || r.rating >= minRating;
        final matchesDist = maxDistance == null || r.distanceKm <= maxDistance;
        return matchesQuery && matchesCuisine && matchesPrice && matchesRating && matchesDist;
      }).toList();

      switch (sortBy) {
        case 'Rating (High to Low)':
          results.sort((a, b) => b.rating.compareTo(a.rating)); break;
        case 'Distance':
          results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm)); break;
        case 'Price (Low to High)':
          results.sort((a, b) => a.priceRange.length.compareTo(b.priceRange.length)); break;
        case 'Price (High to Low)':
          results.sort((a, b) => b.priceRange.length.compareTo(a.priceRange.length)); break;
      }
      _searchResults = results;
      _error = null;
    } catch (e) {
      _error = 'Search failed';
    } finally {
      _setLoading(false);
    }
  }

  void selectRestaurant(RestaurantModel r) {
    _selectedRestaurant = r;
    notifyListeners();
  }

  void toggleFavorite(String restaurantId) {
    _restaurants = _restaurants.map((r) {
      if (r.id == restaurantId) return r.copyWith(isFavorite: !r.isFavorite);
      return r;
    }).toList();
    _searchResults = _searchResults.map((r) {
      if (r.id == restaurantId) return r.copyWith(isFavorite: !r.isFavorite);
      return r;
    }).toList();
    if (_selectedRestaurant?.id == restaurantId) {
      _selectedRestaurant = _selectedRestaurant?.copyWith(
        isFavorite: !(_selectedRestaurant!.isFavorite),
      );
    }
    // TODO: Firestore().collection('users').doc(uid).update({'favorites': FieldValue.arrayUnion/Remove([restaurantId])})
    notifyListeners();
  }

  List<RestaurantModel> get featuredRestaurants =>
      _restaurants.where((r) => r.rating >= 4.5).take(5).toList();

  List<RestaurantModel> get nearbyRestaurants =>
      [..._restaurants]..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

  List<RestaurantModel> get topRated =>
      [..._restaurants]..sort((a, b) => b.rating.compareTo(a.rating));

  List<String> get availableCuisines =>
      _restaurants.map((r) => r.cuisine).toSet().toList();

  // ─── Mock data ───────────────────────────────────────────────────────────────
  List<RestaurantModel> _mockRestaurants() => [
    RestaurantModel(
      id: 'r1', name: 'The Spice Garden', cuisine: 'Indian',
      description: 'Authentic Indian cuisine crafted with traditional spices and modern techniques. '
          'Our chefs bring flavors straight from the subcontinent.',
      address: '42 Galle Road', city: 'Colombo',
      rating: 4.8, reviewCount: 342, priceRange: r'$$',
      imageUrls: ['https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=800'],
      phoneNumber: '+94 11 234 5678',
      distanceKm: 0.8,
      tags: ['Spicy', 'Vegetarian-friendly', 'Dine-in', 'Takeaway'],
      hours: {
        'Mon-Fri': RestaurantHours(open: '11:00 AM', close: '10:00 PM'),
        'Sat-Sun': RestaurantHours(open: '10:00 AM', close: '11:00 PM'),
      },
      menuCategories: _mockMenu(),
      reviews: _mockReviews(),
      isOpen: true,
    ),
    RestaurantModel(
      id: 'r2', name: 'Sakura Japanese', cuisine: 'Japanese',
      description: 'Premium sushi, ramen and teppanyaki in an elegant Japanese atmosphere.',
      address: '18 Union Place', city: 'Colombo',
      rating: 4.7, reviewCount: 215, priceRange: r'$$$',
      imageUrls: ['https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=800'],
      phoneNumber: '+94 11 345 6789',
      distanceKm: 1.5,
      tags: ['Sushi', 'Ramen', 'Teppanyaki', 'Fine Dining'],
      menuCategories: _mockMenu(),
      reviews: _mockReviews(),
      isOpen: true,
    ),
    RestaurantModel(
      id: 'r3', name: 'La Bella Italia', cuisine: 'Italian',
      description: 'Handcrafted pasta, wood-fired pizzas, and an extensive wine selection.',
      address: '7 Dharmapala Mawatha', city: 'Colombo',
      rating: 4.5, reviewCount: 189, priceRange: r'$$',
      imageUrls: ['https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800'],
      phoneNumber: '+94 11 456 7890',
      distanceKm: 2.1,
      tags: ['Pizza', 'Pasta', 'Wine', 'Romantic'],
      menuCategories: _mockMenu(),
      reviews: _mockReviews(),
      isOpen: true,
    ),
    RestaurantModel(
      id: 'r4', name: 'Dragon Palace', cuisine: 'Chinese',
      description: 'Authentic dim sum, Peking duck and Cantonese cuisine in a vibrant setting.',
      address: '23 Pettah Market Road', city: 'Colombo',
      rating: 4.3, reviewCount: 278, priceRange: r'$$',
      imageUrls: ['https://images.unsplash.com/photo-1563245372-f21724e3856d?w=800'],
      phoneNumber: '+94 11 567 8901',
      distanceKm: 3.4,
      tags: ['Dim Sum', 'Takeaway', 'Family'],
      menuCategories: _mockMenu(),
      reviews: _mockReviews(),
      isOpen: false,
    ),
    RestaurantModel(
      id: 'r5', name: 'Ocean Breeze Seafood', cuisine: 'Seafood',
      description: 'Fresh catch of the day, grilled to perfection with ocean-side views.',
      address: '1 Marine Drive', city: 'Colombo',
      rating: 4.6, reviewCount: 156, priceRange: r'$$$',
      imageUrls: ['https://images.unsplash.com/photo-1559339352-11d035aa65de?w=800'],
      phoneNumber: '+94 11 678 9012',
      distanceKm: 0.5,
      tags: ['Seafood', 'Ocean View', 'Grilled'],
      menuCategories: _mockMenu(),
      reviews: _mockReviews(),
      isOpen: true,
    ),
    RestaurantModel(
      id: 'r6', name: 'The Green Bowl', cuisine: 'Vegan',
      description: 'Plant-based, whole food dishes crafted with 100% organic ingredients.',
      address: '55 Horton Place', city: 'Colombo',
      rating: 4.4, reviewCount: 94, priceRange: r'$',
      imageUrls: ['https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800'],
      phoneNumber: '+94 11 789 0123',
      distanceKm: 1.9,
      tags: ['Vegan', 'Organic', 'Healthy', 'Gluten-free'],
      menuCategories: _mockMenu(),
      reviews: _mockReviews(),
      isOpen: true,
    ),
    RestaurantModel(
      id: 'r7', name: 'Café Colombo', cuisine: 'Cafe',
      description: 'Artisanal coffee, fresh pastries and light meals in a cozy atmosphere.',
      address: '12 Independence Avenue', city: 'Colombo',
      rating: 4.2, reviewCount: 312, priceRange: r'$',
      imageUrls: ['https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800'],
      phoneNumber: '+94 11 890 1234',
      distanceKm: 0.3,
      tags: ['Coffee', 'Brunch', 'Work-friendly', 'WiFi'],
      menuCategories: _mockMenu(),
      reviews: _mockReviews(),
      isOpen: true,
    ),
    RestaurantModel(
      id: 'r8', name: 'Taco Fiesta', cuisine: 'Mexican',
      description: 'Bold, vibrant Mexican street food with fresh ingredients and bold salsas.',
      address: '99 Bauddhaloka Mawatha', city: 'Colombo',
      rating: 4.1, reviewCount: 87, priceRange: r'$',
      imageUrls: ['https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800'],
      phoneNumber: '+94 11 901 2345',
      distanceKm: 4.2,
      tags: ['Tacos', 'Casual', 'Fast', 'Spicy'],
      menuCategories: _mockMenu(),
      reviews: _mockReviews(),
      isOpen: true,
    ),
  ];

  List<MenuCategory> _mockMenu() => [
    MenuCategory(id: 'c1', name: 'Starters', items: [
      const MenuItem(id: 'i1', name: 'Garden Salad', description: 'Fresh seasonal greens with balsamic dressing', price: 850, isVegetarian: true, isAvailable: true),
      const MenuItem(id: 'i2', name: 'Soup of the Day', description: 'Chef\'s selection of freshly prepared soup', price: 650, isAvailable: true, isPopular: true),
      const MenuItem(id: 'i3', name: 'Bruschetta', description: 'Toasted bread with tomatoes, basil and olive oil', price: 950, isVegetarian: true, isAvailable: false),
    ]),
    MenuCategory(id: 'c2', name: 'Main Course', items: [
      const MenuItem(id: 'i4', name: 'Grilled Chicken', description: 'Free-range chicken with herb marinade and seasonal vegetables', price: 2200, isPopular: true, isAvailable: true),
      const MenuItem(id: 'i5', name: 'Vegetable Curry', description: 'Slow-cooked seasonal vegetables in aromatic curry sauce', price: 1600, isVegetarian: true, isVegan: true, isAvailable: true),
      const MenuItem(id: 'i6', name: 'Grilled Salmon', description: 'Norwegian salmon fillet with lemon butter sauce', price: 3200, isAvailable: true, isPopular: true),
      const MenuItem(id: 'i7', name: 'Pasta Carbonara', description: 'Classic Italian pasta with egg, pecorino and pancetta', price: 1900, isAvailable: true),
    ]),
    MenuCategory(id: 'c3', name: 'Desserts', items: [
      const MenuItem(id: 'i8', name: 'Chocolate Lava Cake', description: 'Warm chocolate cake with molten centre, served with ice cream', price: 1100, isPopular: true, isAvailable: true),
      const MenuItem(id: 'i9', name: 'Crème Brûlée', description: 'Classic French vanilla custard with caramelised sugar crust', price: 980, isVegetarian: true, isAvailable: false),
    ]),
    MenuCategory(id: 'c4', name: 'Beverages', items: [
      const MenuItem(id: 'i10', name: 'Fresh Lime Soda', description: 'Freshly squeezed lime with sparkling water', price: 450, isVegan: true, isAvailable: true),
      const MenuItem(id: 'i11', name: 'Mango Smoothie', description: 'Chilled fresh mango blended with yoghurt', price: 680, isVegetarian: true, isAvailable: true, isPopular: true),
    ]),
  ];

  List<ReviewModel> _mockReviews() => [
    ReviewModel(
      id: 'rv1', userId: 'u1', userName: 'Sarah M.', rating: 5.0,
      comment: 'Absolutely wonderful experience! The food was exceptional and service was top-notch. Will definitely come back.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)), helpfulCount: 12,
    ),
    ReviewModel(
      id: 'rv2', userId: 'u2', userName: 'James K.', rating: 4.0,
      comment: 'Great ambiance and tasty food. The wait was a bit long but worth it overall.',
      createdAt: DateTime.now().subtract(const Duration(days: 7)), helpfulCount: 5,
    ),
    ReviewModel(
      id: 'rv3', userId: 'u3', userName: 'Priya D.', rating: 4.5,
      comment: 'Loved the vegetarian options! Really thoughtful menu with great flavors.',
      createdAt: DateTime.now().subtract(const Duration(days: 14)), helpfulCount: 8,
    ),
  ];
}
