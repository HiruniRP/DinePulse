// Shared User Model for DinePulse Firebase Backend

enum UserRole {
  customer,
  staff,
  manager,
  admin;

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'staff':
        return UserRole.staff;
      case 'manager':
        return UserRole.manager;
      case 'admin':
        return UserRole.admin;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }

  String get value => name;
}

class SharedUserModel {
  final String uid;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? photoUrl;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic> metadata;

  const SharedUserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.photoUrl,
    this.role = UserRole.customer,
    required this.createdAt,
    this.lastLoginAt,
    this.metadata = const {},
  });

  // Role-Based Access Controls (RBAC)
  bool get isCustomer => role == UserRole.customer;
  bool get isStaff => role == UserRole.staff || role == UserRole.manager || role == UserRole.admin;
  bool get isManager => role == UserRole.manager || role == UserRole.admin;
  bool get isAdmin => role == UserRole.admin;

  bool get canManageReservations => isStaff;
  bool get canManageQueue => isStaff;
  bool get canManageTables => isStaff;
  bool get canEditRestaurantDetails => isManager;

  factory SharedUserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return SharedUserModel(
      uid: id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? data['name'] ?? '',
      phoneNumber: data['phoneNumber'] ?? data['phone'],
      photoUrl: data['photoUrl'] ?? data['avatarUrl'],
      role: UserRole.fromString(data['role']),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is DateTime
              ? data['createdAt'] as DateTime
              : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] is DateTime
              ? data['lastLoginAt'] as DateTime
              : DateTime.tryParse(data['lastLoginAt'].toString()))
          : null,
      metadata: (data['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'role': role.value,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  SharedUserModel copyWith({
    String? fullName,
    String? phoneNumber,
    String? photoUrl,
    UserRole? role,
    DateTime? lastLoginAt,
    Map<String, dynamic>? metadata,
  }) {
    return SharedUserModel(
      uid: uid,
      email: email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
