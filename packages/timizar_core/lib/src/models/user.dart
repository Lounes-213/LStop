enum UserRole {
  passenger,
  driver,
  admin;

  static UserRole fromString(String role) {
    return switch (role.toLowerCase()) {
      'driver' => UserRole.driver,
      'admin' => UserRole.admin,
      _ => UserRole.passenger,
    };
  }
}

class User {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final UserRole role;
  final String? phone;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.role,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'passenger'),
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'avatarUrl': avatarUrl,
    'role': role.name,
    'phone': phone,
  };
}

