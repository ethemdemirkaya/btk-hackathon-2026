import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../../core/storage/auth_storage.dart';

class AuthState {
  final bool isAuthenticated;
  final UserModel? user;
  final bool isLoading;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.isLoading = true,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    UserModel? user,
    bool? isLoading,
  }) =>
      AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> initialize() async {
    final hasToken = await AuthStorage.hasToken();
    state = state.copyWith(isAuthenticated: hasToken, isLoading: false);
  }

  void setAuthenticated(UserModel user) {
    state = state.copyWith(isAuthenticated: true, user: user, isLoading: false);
  }

  void setUnauthenticated() {
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }

  Future<void> logout() async {
    await AuthStorage.clear();
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
