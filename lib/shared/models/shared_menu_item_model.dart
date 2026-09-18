// Shared Menu Item Model for DinePulse Firebase Backend

class SharedMenuItemModel {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final String category; // 'Starters', 'Mains', 'Desserts', 'Beverages', 'Chef Specials'
  final String? imageUrl;
  final bool isAvailable;
  final bool isVegetarian;
  final bool isSpicy;
  final int preparationTimeMinutes;

  const SharedMenuItemModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    this.isAvailable = true,
    this.isVegetarian = false,
    this.isSpicy = false,
    this.preparationTimeMinutes = 15,
  });

  factory SharedMenuItemModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SharedMenuItemModel(
      id: id,
      restaurantId: data['restaurantId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? 'Mains',
      imageUrl: data['imageUrl'],
      isAvailable: data['isAvailable'] ?? true,
      isVegetarian: data['isVegetarian'] ?? false,
      isSpicy: data['isSpicy'] ?? false,
      preparationTimeMinutes: (data['preparationTimeMinutes'] as num?)?.toInt() ?? 15,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'isVegetarian': isVegetarian,
      'isSpicy': isSpicy,
      'preparationTimeMinutes': preparationTimeMinutes,
    };
  }

  SharedMenuItemModel copyWith({
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    bool? isAvailable,
    bool? isVegetarian,
    bool? isSpicy,
    int? preparationTimeMinutes,
  }) {
    return SharedMenuItemModel(
      id: id,
      restaurantId: restaurantId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isSpicy: isSpicy ?? this.isSpicy,
      preparationTimeMinutes: preparationTimeMinutes ?? this.preparationTimeMinutes,
    );
  }
}
