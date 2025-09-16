import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/services.dart';
import '../../providers/providers.dart';
import '../../constants/validation_constants.dart';
import '../../constants/route_constants.dart';

// État de mot de passe oublié
class ForgotPasswordState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const ForgotPasswordState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  ForgotPasswordState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

// Controller de mot de passe oublié
class ForgotPasswordController extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordController(this._authService)
    : super(const ForgotPasswordState());

  final AuthService _authService;

  final emailController = TextEditingController();
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

  // Envoyer l'email de réinitialisation
  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) return;

    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      await _authService.resetPassword(emailController.text.trim());

      state = state.copyWith(
        isLoading: false,
        successMessage:
            'Un email de réinitialisation a été envoyé à ${emailController.text}',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
    }
  }

  // Naviguer vers la connexion
  void goToLogin(BuildContext context) {
    context.go(RouteConstants.login);
  }

  // Effacer les messages
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }

  // Obtenir le message d'erreur approprié
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('User not found')) {
      return 'Aucun compte trouvé avec cette adresse email';
    } else if (error.toString().contains('Invalid email')) {
      return 'Adresse email invalide';
    } else if (error.toString().contains('Too many requests')) {
      return 'Trop de tentatives. Veuillez réessayer plus tard';
    }
    return 'Erreur lors de l\'envoi de l\'email. Veuillez réessayer';
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}

// Provider du controller de mot de passe oublié
final forgotPasswordControllerProvider =
    StateNotifierProvider<ForgotPasswordController, ForgotPasswordState>((ref) {
      final authService = ref.watch(authServiceProvider);
      return ForgotPasswordController(authService);
    });
