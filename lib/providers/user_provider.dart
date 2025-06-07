import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());

final userListProvider = FutureProvider<List<User>>((ref) async {
  return ref.read(userServiceProvider).getAllUsers();
});
