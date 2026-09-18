// Shared Restaurant Model for DinePulse Firebase Backend

class SharedRestaurantModel {
  final String id;
  final String name;
  final String description;
  final String cuisine;
  final String address;
  final String city;
  final double rating;
  final int reviewCount;
  final String priceRange; // '$', '$$', '$$$', '$$$$'
  final List<String> imageUrls;
  final bool isOpen;
  final String openingTime;
  final String closingTime;
  final String? phoneNumber;
  final double latitude;
  final double longitude;

  // Cross-member live sync fields (Member 1 discovery, Member 2 reservation, Member 4 queue)
  final int currentWaitMinutes;
  final int activeQueueLength;
  final int totalTables;
  final int availableTablesCount;

  const SharedRestaurantModel({
    required this.id,
    required this.name,
    required this.description,
    required this.cuisine,
    required this.address,
    required this.city,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.priceRange = r'$$',
    this.imageUrls = const [],
    this.isOpen = true,
    this.openingTime = '11:00 AM',
    this.closingTime = '10:00 PM',
    this.phoneNumber,
    this.latitude = 6.9271,
    this.longitude = 79.8612,
    this.currentWaitMinutes = 0,
    this.activeQueueLength = 0,
    this.totalTables = 0,
    this.availableTablesCount = 0,
  });

  String get mainImage => imageUrls.isNotEmpty ? imageUrls.first : '';

  factory SharedRestaurantModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SharedRestaurantModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      cuisine: data['cuisine'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      priceRange: data['priceRange'] ?? r'$$',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      isOpen: data['isOpen'] ?? true,
      openingTime: data['openingTime'] ?? '11:00 AM',
      closingTime: data['closingTime'] ?? '10:00 PM',
      phoneNumber: data['phoneNumber'],
      latitude: (data['latitude'] as num?)?.toDouble() ?? 6.9271,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 79.8612,
      currentWaitMinutes: (data['currentWaitMinutes'] as num?)?.toInt() ?? 0,
      activeQueueLength: (data['activeQueueLength'] as num?)?.toInt() ?? 0,
      totalTables: (data['totalTables'] as num?)?.toInt() ?? 0,
      availableTablesCount: (data['availableTablesCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'cuisine': cuisine,
      'address': address,
      'city': city,
      'rating': rating,
      'reviewCount': reviewCount,
      'priceRange': priceRange,
      'imageUrls': imageUrls,
      'isOpen': isOpen,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'phoneNumber': phoneNumber,
      'latitude': latitude,
      'longitude': longitude,
      'currentWaitMinutes': currentWaitMinutes,
      'activeQueueLength': activeQueueLength,
      'totalTables': totalTables,
      'availableTablesCount': availableTablesCount,
    };
  }

  SharedRestaurantModel copyWith({
    String? name,
    String? description,
    String? cuisine,
    String? address,
    String? city,
    double? rating,
    int? reviewCount,
    String? priceRange,
    List<String>? imageUrls,
    bool? isOpen,
    String? openingTime,
    String? closingTime,
    String? phoneNumber,
    double? latitude,
    double? longitude,
    int? currentWaitMinutes,
    int? activeQueueLength,
    int? totalTables,
    int? availableTablesCount,
  }) {
    return SharedRestaurantModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      cuisine: cuisine ?? this.cuisine,
      address: address ?? this.address,
      city: city ?? this.city,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      priceRange: priceRange ?? this.priceRange,
      imageUrls: imageUrls ?? this.imageUrls,
      isOpen: isOpen ?? this.isOpen,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      currentWaitMinutes: currentWaitMinutes ?? this.currentWaitMinutes,
      activeQueueLength: activeQueueLength ?? this.activeQueueLength,
      totalTables: totalTables ?? this.totalTables,
      availableTablesCount: availableTablesCount ?? this.availableTablesCount,
    );
  }
}
