import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_endpoints.dart';
import '../models/task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Task>> fetchAllTasks() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/tasks'), // for admin
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List jsonList = json.decode(response.body);
      return jsonList.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch all tasks (Admin)');
    }
  }

  Future<List<Task>> fetchMyTasks() async {
    final token = await _getToken();

    if (token == null) {
      throw Exception("Not authenticated");
    }

    final response = await http.get(
      Uri.parse('$baseUrl/tasks/my'),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final List jsonList = json.decode(response.body);
      return jsonList.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch user tasks');
    }
  }

  Future<bool> createTask({
    required String title,
    String? description,
    required List<String> assignedTo,
    required String priority,
    required DateTime dueDate,
  }) async {
    final token = await _getToken();

    final body = {
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'priority': priority,
      'dueDate': dueDate.toIso8601String(),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) return true;

    throw Exception(jsonDecode(response.body)['message']);
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    final token = await _getToken();

    final response = await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({'status': newStatus}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update task status");
    }
  }
}
