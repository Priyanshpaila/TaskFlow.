import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_flow_app/views/admin/admin_dashboard.dart';
import 'package:task_flow_app/views/auth/auth_selection.dart';
import 'package:task_flow_app/views/user/user_dashboard.dart';
import '../../state/auth_state.dart';

class AuthInitializer extends ConsumerWidget {
  const AuthInitializer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return auth.when(
      data: (user) {
        if (user == null) {
          return const AuthSelectionPage(); // your existing selector
        } else if (user.role == 'admin') {
          return const AdminDashboard();
        } else {
          return const UserDashboard();
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error loading user: $e')),
      ),
    );
  }
}
