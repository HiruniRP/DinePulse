class RestaurantModel {
  final String id;
  final String name;
  final String description;
  final String cuisine;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviewCount;
  final String priceRange; // $, $$, $$$, $$$$
  final List<String> imageUrls;
  final String phoneNumber;
  final String email;
  final String website;
  final Map<String, RestaurantHours> hours;
  final bool isOpen;
  final bool isFavorite;
  final double distanceKm;
  final List<MenuCategory> menuCategories;
  final List<ReviewModel> reviews;
  final List<String> tags;
  final int totalSeats;
  final bool acceptsReservations;
  final bool hasQueue;

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.description,
    required this.cuisine,
    required this.address,
    required this.city,
    this.latitude = 0.0,
    this.longitude = 0.0,
    required this.rating,
    required this.reviewCount,
    required this.priceRange,
    required this.imageUrls,
    this.phoneNumber = '',
    this.email = '',
    this.website = '',
    this.hours = const {},
    this.isOpen = true,
    this.isFavorite = false,
    this.distanceKm = 0.0,
    this.menuCategories = const [],
    this.reviews = const [],
    this.tags = const [],
    this.totalSeats = 50,
    this.acceptsReservations = true,
    this.hasQueue = true,
  });

  RestaurantModel copyWith({
    String? id,
    String? name,
    String? description,
    String? cuisine,
    String? address,
    String? city,
    double? rating,
    int? reviewCount,
    String? priceRange,
    List<String>? imageUrls,
    String? phoneNumber,
    bool? isOpen,
    bool? isFavorite,
    double? distanceKm,
    List<MenuCategory>? menuCategories,
    List<ReviewModel>? reviews,
    List<String>? tags,
  }) {
    return RestaurantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      cuisine: cuisine ?? this.cuisine,
      address: address ?? this.address,
      city: city ?? this.city,
      latitude: latitude,
      longitude: longitude,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      priceRange: priceRange ?? this.priceRange,
      imageUrls: imageUrls ?? this.imageUrls,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email,
      website: website,
      hours: hours,
      isOpen: isOpen ?? this.isOpen,
      isFavorite: isFavorite ?? this.isFavorite,
      distanceKm: distanceKm ?? this.distanceKm,
      menuCategories: menuCategories ?? this.menuCategories,
      reviews: reviews ?? this.reviews,
      tags: tags ?? this.tags,
      totalSeats: totalSeats,
      acceptsReservations: acceptsReservations,
      hasQueue: hasQueue,
    );
  }

  factory RestaurantModel.fromFirestore(Map<String, dynamic> data, String id) {
    return RestaurantModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      cuisine: data['cuisine'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      priceRange: data['priceRange'] ?? '\$',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      phoneNumber: data['phoneNumber'] ?? '',
      email: data['email'] ?? '',
      website: data['website'] ?? '',
      isOpen: data['isOpen'] ?? true,
      totalSeats: data['totalSeats'] ?? 50,
      acceptsReservations: data['acceptsReservations'] ?? true,
      hasQueue: data['hasQueue'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'description': description,
    'cuisine': cuisine,
    'address': address,
    'city': city,
    'latitude': latitude,
    'longitude': longitude,
    'rating': rating,
    'reviewCount': reviewCount,
    'priceRange': priceRange,
    'imageUrls': imageUrls,
    'phoneNumber': phoneNumber,
    'email': email,
    'website': website,
    'isOpen': isOpen,
    'totalSeats': totalSeats,
    'acceptsReservations': acceptsReservations,
    'hasQueue': hasQueue,
  };
}

class RestaurantHours {
  final String open;
  final String close;
  final bool isClosed;

  const RestaurantHours({
    required this.open,
    required this.close,
    this.isClosed = false,
  });
}

class MenuCategory {
  final String id;
  final String name;
  final List<MenuItem> items;

  const MenuCategory({
    required this.id,
    required this.name,
    required this.items,
  });
}

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final bool isAvailable;
  final bool isVegetarian;
  final bool isVegan;
  final bool isPopular;
  final List<String> allergens;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.isAvailable = true,
    this.isVegetarian = false,
    this.isVegan = false,
    this.isPopular = false,
    this.allergens = const [],
  });
}

class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final int helpfulCount;

  const ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.helpfulCount = 0,
  });

  factory ReviewModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ReviewModel(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userAvatar: data['userAvatar'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      helpfulCount: data['helpfulCount'] ?? 0,
    );
  }
}
