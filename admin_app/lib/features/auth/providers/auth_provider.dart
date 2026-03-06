import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

// Modern Riverpod Notifier implementation
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  AuthState({
    required this.isLoading,
    required this.isAuthenticated,
    this.error,
  });

  factory AuthState.initial() => AuthState(isLoading: true, isAuthenticated: false);

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error ?? this.error,
    );
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkAuth();
    return AuthState.initial();
  }

  Future<void> _checkAuth() async {
    final authService = ref.read(authServiceProvider);
    final isAuth = await authService.isLoggedIn();
    state = state.copyWith(isLoading: false, isAuthenticated: isAuth);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final authService = ref.read(authServiceProvider);
    final result = await authService.login(email, password);
    
    if (result['success']) {
      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return true;
    } else {
      state = state.copyWith(isLoading: false, isAuthenticated: false, error: result['message']);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final authService = ref.read(authServiceProvider);
    final result = await authService.register(
      name: name,
      email: email,
      password: password,
    );

    if (result['success']) {
      state = state.copyWith(isLoading: false);
      return true;
    } else {
      state = state.copyWith(isLoading: false, error: result['message']);
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    state = state.copyWith(isLoading: false, isAuthenticated: false);
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
