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
      final tasks = jsonList.map((json) => Task.fromJson(json)).toList();
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role') ?? 'user';
      final currentUserId = prefs.getString(
        'userId',
      ); // get user ID for self-assigned check

      return tasks.where((task) {
        // Ensure self-assigned tasks are also shown if the current user is in assignedTo
        if (role == 'admin' && currentUserId != null) {
          return task.createdBy == currentUserId ||
              task.assignedTo.contains(currentUserId);
        }

        return true;
      }).toList();
    } else {
      final msg =
          jsonDecode(response.body)['message'] ?? 'Error fetching tasks';
      throw Exception('Failed to fetch all tasks: $msg');
    }
  }

  /// User: Fetch all tasks assigned to logged-in user
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

  /// Admin: Create a new task
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

  /// User: Create personal/self task
  Future<bool> createPersonalTask({
    required String title,
    String? description,
    required String priority,
    required DateTime dueDate,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final body = {
      'title': title,
      'description': description ?? '',
      'priority': priority,
      'dueDate': dueDate.toIso8601String(),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/tasks/public'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) return true;

    final msg =
        jsonDecode(response.body)['message'] ?? 'Personal task creation failed';
    throw Exception(msg);
  }

  /// User/Admin: Update task status
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

  /// ✅ Edit an existing task (Admin or Task Creator)
  Future<void> editTask({
    required String taskId,
    required String title,
    String? description,
    List<String>? assignedTo,
    required String priority,
    required DateTime dueDate,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final body = {
      'title': title,
      'description': description ?? '',
      if (assignedTo != null) 'assignedTo': assignedTo,
      'priority': priority,
      'dueDate': dueDate.toIso8601String(),
    };

    final response = await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId/edit'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final msg = jsonDecode(response.body)['message'] ?? 'Task update failed';
      throw Exception(msg);
    }
  }
}
