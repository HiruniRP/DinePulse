class CustomerModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? preferredCuisine;
  final List<String> favoriteCuisines;
  final List<String> dietaryPreferences;
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool smsNotifications;
  final String role; // 'customer', 'staff', 'manager', 'admin'
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CustomerModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.role = 'customer',
    this.phoneNumber,
    this.avatarUrl,
    this.dateOfBirth,
    this.preferredCuisine,
    this.favoriteCuisines = const [],
    this.dietaryPreferences = const [],
    this.notificationsEnabled = true,
    this.emailNotifications = true,
    this.smsNotifications = false,
    required this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  bool get isStaff => role == 'staff' || role == 'manager' || role == 'admin';

  CustomerModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    String? phoneNumber,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? preferredCuisine,
    List<String>? favoriteCuisines,
    List<String>? dietaryPreferences,
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? smsNotifications,
  }) {
    return CustomerModel(
      uid: uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      preferredCuisine: preferredCuisine ?? this.preferredCuisine,
      favoriteCuisines: favoriteCuisines ?? this.favoriteCuisines,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  factory CustomerModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return CustomerModel(
      uid: uid,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'customer',
      phoneNumber: data['phoneNumber'],
      avatarUrl: data['avatarUrl'],
      preferredCuisine: data['preferredCuisine'],
      favoriteCuisines: List<String>.from(data['favoriteCuisines'] ?? []),
      dietaryPreferences: List<String>.from(data['dietaryPreferences'] ?? []),
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      emailNotifications: data['emailNotifications'] ?? true,
      smsNotifications: data['smsNotifications'] ?? false,
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: data['updatedAt'] != null ? DateTime.tryParse(data['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'role': role,
    'phoneNumber': phoneNumber,
    'avatarUrl': avatarUrl,
    'preferredCuisine': preferredCuisine,
    'favoriteCuisines': favoriteCuisines,
    'dietaryPreferences': dietaryPreferences,
    'notificationsEnabled': notificationsEnabled,
    'emailNotifications': emailNotifications,
    'smsNotifications': smsNotifications,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': DateTime.now().toIso8601String(),
  };
}
