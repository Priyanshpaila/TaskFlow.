// models/user_model.dart
class User {
  final String id;
  final String username;
  final String email;
  final String role;
  final String status;
  final String division; // ✅ Added division field

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.status,
    required this.division,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['_id']?.toString() ?? '',
    username: json['username'] ?? '',
    email: json['email'] ?? '',
    role: json['role'] ?? 'user',
    status: json['status'] ?? 'active',
    division: json['division'] ?? '', // ✅ Parse division from JSON
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'username': username,
    'email': email,
    'role': role,
    'status': status,
    'division': division, // ✅ Include division in JSON serialization
  };
}
