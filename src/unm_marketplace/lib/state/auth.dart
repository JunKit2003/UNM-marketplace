import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/models.dart';
import '../core/repositories/auth_repository.dart';
import 'providers.dart';

/// The logged-in user (null when signed out). Connects the chat socket while signed in.
class AuthController extends AsyncNotifier<User?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<User?> build() async {
    final user = await _repo.me();
    _syncSocket(user);
    return user;
  }

  void _syncSocket(User? user) {
    final socket = ref.read(chatSocketProvider);
    if (user == null) {
      socket.disconnect();
    } else {
      socket.connect();
    }
  }

  void _set(User? user) {
    _syncSocket(user);
    state = AsyncData(user);
  }

  Future<User> login(String email, String password) async {
    final u = await _repo.login(email, password);
    _set(u);
    return u;
  }

  Future<User> signup(SignupData data) async {
    final u = await _repo.signup(data);
    _set(u);
    return u;
  }

  Future<User> demo() async {
    final u = await _repo.demo();
    _set(u);
    return u;
  }

  Future<void> logout() async {
    try {
      await _repo.logout();
    } finally {
      _set(null);
    }
  }

  /// Replace the cached user after a profile change.
  void updated(User user) => state = AsyncData(user);
}

final authProvider = AsyncNotifierProvider<AuthController, User?>(AuthController.new);
