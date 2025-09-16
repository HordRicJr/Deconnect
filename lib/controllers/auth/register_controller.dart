import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/services.dart';
import '../../services/auth/auth_service.dart';
import '../../providers/providers.dart';
import '../../constants/validation_constants.dart';
import '../../constants/route_constants.dart';

// État d'inscription
class RegisterState {
  final bool isLoading;
  final String? error;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final bool agreedToTerms;

  const RegisterState({
    this.isLoading = false,
    this.error,
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
    this.agreedToTerms = false,
  });

  RegisterState copyWith({
    bool? isLoading,
    String? error,
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible,
    bool? agreedToTerms,
  }) {
    return RegisterState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isConfirmPasswordVisible:
          isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
    );
  }
}

// Controller d'inscription
class RegisterController extends StateNotifier<RegisterState> {
  RegisterController(this._authService) : super(const RegisterState());

  final AuthService _authService;

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Validation du nom complet
  String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationConstants.requiredFieldError;
    }

    if (value.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }

    return null;
  }

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

    // Vérifications de force du mot de passe
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins une majuscule, une minuscule et un chiffre';
    }

    return null;
  }

  // Validation de la confirmation du mot de passe
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return ValidationConstants.requiredFieldError;
    }

    if (value != passwordController.text) {
      return ValidationConstants.passwordMismatchError;
    }

    return null;
  }

  // Basculer la visibilité du mot de passe
  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  // Basculer la visibilité de la confirmation du mot de passe
  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(
      isConfirmPasswordVisible: !state.isConfirmPasswordVisible,
    );
  }

  // Basculer l'acceptation des conditions
  void toggleTermsAgreement() {
    state = state.copyWith(agreedToTerms: !state.agreedToTerms);
  }

  // Inscription avec email/mot de passe
  Future<void> signUpWithEmail(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    if (!state.agreedToTerms) {
      state = state.copyWith(
        error: 'Vous devez accepter les conditions d\'utilisation',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authService.signUpWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
        fullName: fullNameController.text.trim(),
      );

      if (response.user != null && context.mounted) {
        // Rediriger vers la vérification d'email ou onboarding
        _showEmailVerificationDialog(context);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
    }
  }

  // Inscription avec Google
  Future<void> signUpWithGoogle(BuildContext context) async {
    if (!state.agreedToTerms) {
      state = state.copyWith(
        error: 'Vous devez accepter les conditions d\'utilisation',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _authService.signInWithProvider(
        OAuthProvider.google,
      );

      if (success && context.mounted) {
        context.go(RouteConstants.onboarding);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
    }
  }

  // Inscription avec Apple
  Future<void> signUpWithApple(BuildContext context) async {
    if (!state.agreedToTerms) {
      state = state.copyWith(
        error: 'Vous devez accepter les conditions d\'utilisation',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _authService.signInWithProvider(
        OAuthProvider.apple,
      );

      if (success && context.mounted) {
        context.go(RouteConstants.onboarding);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
    }
  }

  // Naviguer vers la connexion
  void goToLogin(BuildContext context) {
    context.go(RouteConstants.login);
  }

  // Afficher les conditions d'utilisation
  void showTermsOfService(BuildContext context) {
    // À implémenter : ouvrir les CGU
  }

  // Afficher la politique de confidentialité
  void showPrivacyPolicy(BuildContext context) {
    // À implémenter : ouvrir la politique de confidentialité
  }

  // Effacer l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Afficher le dialogue de vérification d'email
  void _showEmailVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Vérifiez votre email'),
        content: Text(
          'Un email de confirmation a été envoyé à ${emailController.text}. '
          'Veuillez cliquer sur le lien pour activer votre compte.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go(RouteConstants.login);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Obtenir le message d'erreur approprié
  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('User already registered')) {
      return 'Cette adresse email est déjà utilisée';
    } else if (error.toString().contains('Password should be at least')) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    } else if (error.toString().contains('Invalid email')) {
      return 'Adresse email invalide';
    }
    return 'Erreur lors de l\'inscription. Veuillez réessayer';
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}

// Provider du controller d'inscription
final registerControllerProvider =
    StateNotifierProvider<RegisterController, RegisterState>((ref) {
      final authService = ref.watch(authServiceProvider);
      return RegisterController(authService);
    });
