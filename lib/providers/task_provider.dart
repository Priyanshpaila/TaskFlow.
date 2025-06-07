import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_flow_app/state/auth_state.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

final taskServiceProvider = Provider<TaskService>((ref) => TaskService());

final taskListProvider = FutureProvider<List<Task>>((ref) async {
  final auth = ref.watch(authStateProvider).value;
  final taskService = ref.watch(taskServiceProvider);

  // ✅ No user logged in? Don't call backend
  if (auth == null) {
    return []; // or: throw Exception("No user session")
  }

  if (auth.role == 'admin') {
    return taskService.fetchAllTasks();
  } else {
    return taskService.fetchMyTasks();
  }
});
