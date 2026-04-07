import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_env.dart';
import '../data/auth_repository.dart';
import '../data/mock_auth_repository.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppEnv.hasSupabase) {
    return SupabaseAuthRepository(Supabase.instance.client);
  }

  return MockAuthRepository();
});

final authStatusProvider = StreamProvider<AuthStatus>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

class AuthActionState {
  const AuthActionState({
    this.isLoading = false,
    this.errorMessage,
  });

  final bool isLoading;
  final String? errorMessage;

  AuthActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthActionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends Notifier<AuthActionState> {
  @override
  AuthActionState build() => const AuthActionState();

  Future<bool> signInForDevelopment() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await ref.read(authRepositoryProvider).signInForDevelopment();
      state = const AuthActionState();
      return true;
    } catch (error) {
      state = AuthActionState(
        isLoading: false,
        errorMessage: error.toString(),
      );
      return false;
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthActionState>(AuthController.new);

