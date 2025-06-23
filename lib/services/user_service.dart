import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_endpoints.dart';
import '../models/user_model.dart';

class UserService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ✅ Get all users (Admin only)
  Future<List<User>> getAllUsers() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Token not found. User might not be logged in.");
    }

    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => User.fromJson(json)).toList();
    } else {
      final message =
          json.decode(response.body)['message'] ?? 'Failed to load users';
      throw Exception("Error ${response.statusCode}: $message");
    }
  }

  // ✅ Update user profile
  Future<void> updateUserProfile({
    required String username,
    required String email,
    String? currentPassword,
    String? newPassword,
  }) async {
    final token = await _getToken();
    final body = {
      "username": username,
      "email": email,
      if (currentPassword != null && currentPassword.isNotEmpty)
        "currentPassword": currentPassword,
      if (newPassword != null && newPassword.isNotEmpty)
        "newPassword": newPassword,
    };

    final response = await http.patch(
      Uri.parse('$baseUrl/users/me/update'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final msg =
          jsonDecode(response.body)['message'] ?? 'Profile update failed';
      throw Exception(msg);
    }
  }

  // ✅ Update user status
  Future<void> updateUserStatus(String newStatus) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token not found.");

    final response = await http.patch(
      Uri.parse('$baseUrl/users/status'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"status": newStatus}),
    );

    if (response.statusCode != 200) {
      final msg =
          jsonDecode(response.body)['message'] ?? 'Status update failed';
      throw Exception("Error ${response.statusCode}: $msg");
    }
  }

  // 🔥 NEW: Get all users (Super Admin)
  Future<List<User>> getAllUsersSuperAdmin() async {
    final token = await _getToken();
    if (token == null) throw Exception("Token not found.");

    final response = await http.get(
      Uri.parse(getAllUsersSuperAdminUrl),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List jsonList = json.decode(response.body);
      return jsonList.map((json) => User.fromJson(json)).toList();
    } else {
      final msg =
          jsonDecode(response.body)['message'] ?? 'Failed to load users';
      throw Exception("Error ${response.statusCode}: $msg");
    }
  }

  // 🔥 NEW: Change user role (Super Admin)
  Future<void> changeUserRole(String userId, String newRole) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final url = changeUserRoleUrl.replaceAll(':id', userId);

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'role': newRole}),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to change user role');
      }
    } catch (e) {
      throw Exception('Failed to change user role: $e');
    }
  }
}
