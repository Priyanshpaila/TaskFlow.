// router/app_router.dart
import 'package:flutter/material.dart';
import 'package:task_flow_app/views/admin/admin_profile.dart';
import 'package:task_flow_app/views/allUsers/self_task_create.dart';
import 'package:task_flow_app/views/super_admin/super_admin_all_tasks_page.dart';
import 'package:task_flow_app/views/super_admin/super_admin_all_users_page.dart';
import 'package:task_flow_app/views/super_admin/super_admin_create_task_page.dart';
import 'package:task_flow_app/views/super_admin/super_admin_dashboard.dart';
import 'package:task_flow_app/views/user/user_profile.dart';
import '../views/auth/auth_selection.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/signup_screen.dart';
import '../views/home/home_screen.dart';
import '../views/user/user_dashboard.dart';
import '../views/admin/admin_dashboard.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/auth': (context) => const AuthSelectionPage(),
  '/login': (context) => const LoginScreen(),
  '/signup': (context) => const SignupScreen(),
  '/home': (context) => const HomeScreen(),
  '/admin': (context) => const AdminDashboard(),
  '/user': (context) => const UserDashboard(),
  '/profile': (context) => const UserProfileScreen(),
  '/admin/profile': (context) => const AdminProfileScreen(),
  '/create-personal-task': (context) => const CreatePersonalTaskPage(),
  '/superadmin': (context) => const SuperAdminDashboard(),
  '/superadmin/create-task': (context) => const SuperAdminCreateTaskPage(),
  '/superadmin/all-tasks': (context) => const SuperAdminAllTasksPage(),
  '/superadmin/all-users': (context) => const SuperAdminAllUsersPage(),
  // '/superadmin/analytics': (context) => const SuperAdminAnalyticsPage(),
};
