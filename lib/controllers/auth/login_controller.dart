import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/services.dart';
import '../../services/auth/auth_service.dart';
import '../../providers/providers.dart';
import '../../constants/validation_constants.dart';
import '../../constants/route_constants.dart';

// État de connexion
class LoginState {
  final bool isLoading;
  final String? error;
  final bool isPasswordVisible;

  const LoginState({
    this.isLoading = false,
    this.error,
    this.isPasswordVisible = false,
  });

  LoginState copyWith({
    bool? isLoading,
    String? error,
    bool? isPasswordVisible,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
    );
  }
}

// Controller de connexion
class LoginController extends StateNotifier<LoginState> {
  LoginController(this._authService) : super(const LoginState());

  final AuthService _authService;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Validation de l'email
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationConstants.requiredFieldError;
    }

    if (!RegExp(ValidationConstants.emailPattern).hasMatch(value)) {
      return ValidationConstants.invalidEmailError;
    }

    return null;
  }

  // Validation du mot de passe
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationConstants.requiredFieldError;
    }

    if (value.length < ValidationConstants.minPasswordLength) {
      return ValidationConstants.passwordTooShortError;
    }

    return null;
  }

  // Basculer la visibilité du mot de passe
  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  // Connexion avec email/mot de passe
  Future<void> signInWithEmail(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authService.signInWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (response.user != null && context.mounted) {
        context.go(RouteConstants.home);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
    }
  }

  // Connexion avec Google
  Future<void> signInWithGoogle(BuildContext context) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _authService.signInWithProvider(
        OAuthProvider.google,
      );

      if (success && context.mounted) {
        context.go(RouteConstants.home);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
    }
  }

  // Connexion avec Apple
  Future<void> signInWithApple(BuildContext context) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _authService.signInWithProvider(
        OAuthProvider.apple,
      );

      if (success && context.mounted) {
        context.go(RouteConstants.home);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
    }
  }

  // Naviguer vers l'inscription
  void goToRegister(BuildContext context) {
    context.go(RouteConstants.register);
  }

  // Naviguer vers mot de passe oublié
  void goToForgotPassword(BuildContext context) {
    context.go(RouteConstants.forgotPassword);
  }

  // Effacer l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Obtenir le message d'erreur approprié
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('Invalid login credentials')) {
      return 'Email ou mot de passe incorrect';
    } else if (error.toString().contains('Email not confirmed')) {
      return 'Veuillez confirmer votre email avant de vous connecter';
    } else if (error.toString().contains('Too many requests')) {
      return 'Trop de tentatives. Veuillez réessayer plus tard';
    }
    return 'Erreur de connexion. Veuillez réessayer';
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

// Provider du controller de connexion
final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
      final authService = ref.watch(authServiceProvider);
      return LoginController(authService);
    });
