import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_endpoints.dart';
import '../models/user_model.dart';

class AuthService {
  Future<String?> login(String email, String password) async {
    final res = await http.post(
      Uri.parse(loginUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"email": email, "password": password}),
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      return null; // Success
    } else {
      try {
        final data = json.decode(res.body);
        return data['message'] ?? 'Login failed.';
      } catch (_) {
        return 'Login failed.';
      }
    }
  }

  Future<String?> signup(
    String username,
    String email,
    String password,
    String confirmPassword,
    String division, // ✅ Added division parameter
  ) async {
    final res = await http.post(
      Uri.parse(signupUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "username": username,
        "email": email,
        "password": password,
        "confirmPassword": confirmPassword,
        "division": division, // ✅ Send division to backend
      }),
    );

    if (res.statusCode == 201) return null;
    try {
      final data = json.decode(res.body);
      return data['message'] ?? 'Signup failed.';
    } catch (_) {
      return 'Signup failed.';
    }
  }

  Future<User?> getCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    final res = await http.get(
      Uri.parse(meUrl),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      return User.fromJson(json.decode(res.body));
    } else {
      return null;
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
