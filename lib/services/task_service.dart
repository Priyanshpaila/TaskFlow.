import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_endpoints.dart';
import '../models/task_model.dart';

class TaskService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Admin: Fetch all tasks (filtered by division on backend)
  Future<List<Task>> fetchAllTasks() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Not authenticated");
    }

    final response = await http.get(
      Uri.parse('$baseUrl/tasks'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List jsonList = json.decode(response.body);
      return jsonList.map((json) => Task.fromJson(json)).toList();
    } else {
      final msg =
          jsonDecode(response.body)['message'] ?? 'Error fetching tasks';
      throw Exception('Failed to fetch all tasks: $msg');
    }
  }

  // User: Fetch only tasks assigned to logged-in user
  Future<List<Task>> fetchMyTasks() async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await http.get(
      Uri.parse('$baseUrl/tasks/my'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List jsonList = json.decode(response.body);
      return jsonList.map((json) => Task.fromJson(json)).toList();
    } else {
      final msg =
          jsonDecode(response.body)['message'] ?? 'Error fetching user tasks';
      throw Exception('Failed to fetch user tasks: $msg');
    }
  }

  // Admin: Create a new task
  Future<bool> createTask({
    required String title,
    String? description,
    required List<String> assignedTo,
    required String priority,
    required DateTime dueDate,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final body = {
      'title': title,
      'description': description ?? '',
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

    final msg = jsonDecode(response.body)['message'] ?? 'Task creation failed';
    throw Exception(msg);
  }

  // User: Update task status
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({'status': newStatus}),
    );

    if (response.statusCode != 200) {
      final msg =
          jsonDecode(response.body)['message'] ?? 'Status update failed';
      throw Exception(msg);
    }
  }
}
