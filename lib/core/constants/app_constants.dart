class AppConstants {
  // App info
  static const String appName = 'DinePulse';
  static const String appVersion = '1.0.0';

  // Cuisine types
  static const List<String> cuisineTypes = [
    'All',
    'Italian',
    'Chinese',
    'Japanese',
    'Indian',
    'Mexican',
    'Thai',
    'Mediterranean',
    'American',
    'French',
    'Korean',
    'Sri Lankan',
    'Seafood',
    'Vegetarian',
    'Vegan',
    'Fast Food',
    'Cafe',
    'Dessert',
  ];

  // Price ranges
  static const List<String> priceRanges = [
    'All',
    r'$ (Budget)',
    r'$$ (Moderate)',
    r'$$$ (Upscale)',
    r'$$$$ (Fine Dining)',
  ];

  // Sort options
  static const List<String> sortOptions = [
    'Relevance',
    'Rating (High to Low)',
    'Distance',
    'Price (Low to High)',
    'Price (High to Low)',
    'Newest',
  ];

  // Rating options
  static const List<double> ratingFilters = [0.0, 3.0, 3.5, 4.0, 4.5];

  // Distance options (km)
  static const List<double> distanceOptions = [1.0, 2.0, 5.0, 10.0, 20.0];

  // Reservation statuses
  static const String statusPending = 'pending';
  static const String statusConfirmed = 'confirmed';
  static const String statusCancelled = 'cancelled';
  static const String statusCompleted = 'completed';

  // Notification types
  static const String notifReservation = 'reservation';
  static const String notifPromotion = 'promotion';
  static const String notifReminder = 'reminder';
  static const String notifSystem = 'system';
}
