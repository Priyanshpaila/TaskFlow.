// router/app_router.dart
import 'package:flutter/material.dart';
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
};
