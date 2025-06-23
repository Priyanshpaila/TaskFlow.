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

  // ✅ Admin: Fetch all tasks (own division)
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
      final currentUserId = prefs.getString('userId');

      return tasks.where((task) {
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

  // ✅ Super Admin: Fetch all tasks (no filter)b
  Future<List<Task>> fetchAllTasksForSuperAdmin() async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final response = await http.get(
      Uri.parse(getAllTasksSuperAdminUrl),
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
          jsonDecode(response.body)['message'] ?? 'Failed to fetch tasks';
      throw Exception("Error ${response.statusCode}: $msg");
    }
  }

  // ✅ Super Admin: Create task for any user(s)
  Future<bool> createTaskAsSuperAdmin({
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
      Uri.parse(createTaskSuperAdminUrl),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) return true;

    final msg =
        jsonDecode(response.body)['message'] ?? 'Super Admin task creation failed';
    throw Exception(msg);
  }

  // ✅ User: Fetch own tasks
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

  // ✅ Admin: Create a new task
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

  // ✅ User: Create personal task
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

  // ✅ Update task status
  Future<void> updateTaskStatus({
    required String taskId,
    required String newStatus,
    String? reason,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception("Not authenticated");

    final Map<String, dynamic> body = {
      'status': newStatus,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason,
    };

    final response = await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final msg =
          jsonDecode(response.body)['message'] ?? 'Status update failed';
      throw Exception(msg);
    }
  }

  // ✅ Edit a task (Admin or creator)
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
