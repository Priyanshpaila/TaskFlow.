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

  Future<List<User>> getAllUsers() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Token not found. User might not be logged in.");
    }

    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type":
            "application/json", // ✅ Optional but good for consistency
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
    final msg = jsonDecode(response.body)['message'] ?? 'Profile update failed';
    throw Exception(msg);
  }
}

}
