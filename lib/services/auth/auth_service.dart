import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gotrue/gotrue.dart' as gotrue;

import '../../models/profile.dart';
import '../supabase_service.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  // Stream pour écouter les changements d'état d'authentification
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Utilisateur actuel
  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  // Vérifier si l'utilisateur est connecté
  bool get isAuthenticated => currentUser != null;

  // Inscription avec email/mot de passe
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, ...?metadata},
      );

      return response;
    } catch (e) {
      throw AuthException('Erreur lors de l\'inscription: $e');
    }
  }

  // Connexion avec email/mot de passe
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response;
    } catch (e) {
      throw AuthException('Erreur lors de la connexion: $e');
    }
  }

  // Connexion avec fournisseur OAuth (Google, Apple, etc.)
  Future<bool> signInWithProvider(OAuthProvider provider) async {
    try {
      // Convertir notre enum vers le provider Supabase
      gotrue.OAuthProvider supabaseProvider;
      switch (provider) {
        case OAuthProvider.google:
          supabaseProvider = gotrue.OAuthProvider.google;
          break;
        case OAuthProvider.apple:
          supabaseProvider = gotrue.OAuthProvider.apple;
          break;
        case OAuthProvider.facebook:
          supabaseProvider = gotrue.OAuthProvider.facebook;
          break;
        case OAuthProvider.twitter:
          supabaseProvider = gotrue.OAuthProvider.twitter;
          break;
        case OAuthProvider.github:
          supabaseProvider = gotrue.OAuthProvider.github;
          break;
      }

      final response = await _client.auth.signInWithOAuth(
        supabaseProvider,
        redirectTo: 'com.deconnect://auth-callback',
      );

      return response;
    } catch (e) {
      throw AuthException('Erreur lors de la connexion OAuth: $e');
    }
  }

  // Connexion anonyme
  Future<AuthResponse> signInAnonymously() async {
    try {
      final response = await _client.auth.signInAnonymously();
      return response;
    } catch (e) {
      throw AuthException('Erreur lors de la connexion anonyme: $e');
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw AuthException('Erreur lors de la déconnexion: $e');
    }
  }

  // Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.deconnect://reset-password',
      );
    } catch (e) {
      throw AuthException('Erreur lors de la réinitialisation: $e');
    }
  }

  // Mise à jour du mot de passe
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return response;
    } catch (e) {
      throw AuthException('Erreur lors de la mise à jour du mot de passe: $e');
    }
  }

  // Mise à jour des métadonnées utilisateur
  Future<UserResponse> updateUserMetadata(Map<String, dynamic> data) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(data: data),
      );

      return response;
    } catch (e) {
      throw AuthException('Erreur lors de la mise à jour des métadonnées: $e');
    }
  }

  // Récupérer le profil utilisateur complet
  Future<Profile?> getUserProfile() async {
    if (!isAuthenticated) return null;

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();

      if (response == null) return null;

      return Profile.fromJson(response);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du profil: $e');
    }
  }

  // Vérifier si l'email existe déjà
  Future<bool> emailExists(String email) async {
    try {
      // Note: Cette méthode nécessite une fonction Supabase edge function
      // ou une requête RPC personnalisée pour des raisons de sécurité
      final response = await _client.rpc(
        'check_email_exists',
        params: {'email_to_check': email},
      );

      return response as bool;
    } catch (e) {
      // Si la fonction RPC n'existe pas, on retourne false par défaut
      return false;
    }
  }

  // Rafraîchir la session
  Future<AuthResponse> refreshSession() async {
    try {
      final response = await _client.auth.refreshSession();
      return response;
    } catch (e) {
      throw AuthException('Erreur lors du rafraîchissement de la session: $e');
    }
  }

  // Écouter les changements d'authentification
  StreamSubscription<AuthState> listenToAuthChanges(
    void Function(AuthState) callback,
  ) {
    return authStateChanges.listen(callback);
  }

  // Vérifier la validité du token
  bool get isTokenValid {
    final session = currentSession;
    if (session == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    return session.expiresAt != null && session.expiresAt! > now;
  }

  // Supprimer le compte utilisateur
  Future<void> deleteAccount() async {
    if (!isAuthenticated) {
      throw AuthException('Aucun utilisateur connecté');
    }

    try {
      // Supprimer d'abord les données associées via RPC
      await _client.rpc(
        'delete_user_data',
        params: {'user_id': currentUser!.id},
      );

      // Puis supprimer le compte
      await _client.auth.admin.deleteUser(currentUser!.id);
    } catch (e) {
      throw AuthException('Erreur lors de la suppression du compte: $e');
    }
  }
}

// Enum pour les fournisseurs OAuth
enum OAuthProvider { google, apple, facebook, twitter, github }

// Exception personnalisée pour l'authentification
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
