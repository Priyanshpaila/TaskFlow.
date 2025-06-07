import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>(
      (ref) => AuthNotifier(ref),
    );

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final Ref ref;
  AuthNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await ref.read(authServiceProvider).getCurrentUser();
    state = AsyncValue.data(user);
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    final msg = await ref.read(authServiceProvider).login(email, password);
    if (msg == null) {
      await _loadUser();
    } else {
      state = AsyncValue.error(msg, StackTrace.current);
    }
  }

  Future<void> signup(
    String username,
    String email,
    String pass,
    String confirm,
  ) async {
    state = const AsyncValue.loading();
    final msg = await ref
        .read(authServiceProvider)
        .signup(username, email, pass, confirm);
    if (msg == null) {
      await login(email, pass);
    } else {
      state = AsyncValue.error(msg, StackTrace.current);
    }
  }

  void logout() {
    ref.read(authServiceProvider).logout();
    state = const AsyncValue.data(null);
  }
}
