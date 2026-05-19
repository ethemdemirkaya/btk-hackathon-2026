import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/dio_client.dart';
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
    // Attempt to revoke all tokens on the server. If the request fails
    // (network error, expired token, etc.) we still clear local storage so
    // the user is never left stuck on the authenticated screen.
    try {
      await DioClient.instance.delete(ApiEndpoints.authLogoutAll);
    } on DioException {
      // Ignore — proceed with local cleanup regardless.
    } catch (_) {
      // Ignore any other error as well.
    }
    await AuthStorage.clear();
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Holds the verified UserModel between splash auth-check and PIN confirmation.
// Cleared after setAuthenticated() is called.
final pendingUserProvider = StateProvider<UserModel?>((ref) => null);
