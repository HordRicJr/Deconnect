import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/app_service.dart';

// Provider pour AppService
final appServiceProvider = Provider<AppService>((ref) {
  return AppService.instance;
});

// État de l'authentification
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({User? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Contrôleur d'authentification
class AuthController extends StateNotifier<AuthState> {
  final AppService _appService;

  AuthController(this._appService) : super(AuthState()) {
    _initAuth();
  }

  void _initAuth() {
    final user = _appService.supabase.client.auth.currentUser;
    state = state.copyWith(user: user);
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _appService.supabase.client.auth.signOut();
      state = state.copyWith(user: null, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Implémenter la suppression du compte
      // await _appService.auth.deleteAccount();
      state = state.copyWith(user: null, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Provider pour le contrôleur d'authentification
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final appService = ref.watch(appServiceProvider);
    return AuthController(appService);
  },
);
