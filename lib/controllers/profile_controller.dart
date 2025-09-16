import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/profile.dart';
import '../services/services.dart';
import '../providers/providers.dart';
import '../constants/route_constants.dart';

// État du profil
class ProfileState {
  final Profile? profile;
  final bool isLoading;
  final String? error;
  final bool isEditing;
  final int currentStreak;
  final List<Map<String, dynamic>> recentActivities;
  final List<Map<String, dynamic>> badges;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
    this.isEditing = false,
    this.currentStreak = 0,
    this.recentActivities = const [],
    this.badges = const [],
  });

  ProfileState copyWith({
    Profile? profile,
    bool? isLoading,
    String? error,
    bool? isEditing,
    int? currentStreak,
    List<Map<String, dynamic>>? recentActivities,
    List<Map<String, dynamic>>? badges,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isEditing: isEditing ?? this.isEditing,
      currentStreak: currentStreak ?? this.currentStreak,
      recentActivities: recentActivities ?? this.recentActivities,
      badges: badges ?? this.badges,
    );
  }
}

// Controller du profil
class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._appService, this._authService)
    : super(const ProfileState());

  final AppService _appService;
  final AuthService _authService;

  // Charger le profil utilisateur
  Future<void> loadProfile() async {
    if (!_authService.isAuthenticated) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final profile = await _authService.getUserProfile();
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement du profil: $e',
      );
    }
  }

  // Mettre à jour le profil
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (state.profile == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedProfile = await _appService.profile.updateProfile(
        state.profile!.id,
        updates,
      );

      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
        isEditing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la mise à jour: $e',
      );
    }
  }

  // Télécharger un avatar
  Future<void> uploadAvatar(String imagePath) async {
    if (state.profile == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Logique d'upload d'avatar à implémenter avec StorageService
      // final avatarUrl = await _storageService.uploadAvatar(File(imagePath));

      await updateProfile({
        'avatar_url': imagePath, // Remplacer par l'URL réelle
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de l\'upload de l\'avatar: $e',
      );
    }
  }

  // Déconnexion
  Future<void> signOut(BuildContext context) async {
    try {
      await _authService.signOut();
      if (context.mounted) {
        context.go(RouteConstants.login);
      }
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la déconnexion: $e');
    }
  }

  // Activer le mode édition
  void startEditing() {
    state = state.copyWith(isEditing: true);
  }

  // Annuler l'édition
  void cancelEditing() {
    state = state.copyWith(isEditing: false);
  }

  // Naviguer vers l'édition du profil
  void goToEditProfile(BuildContext context) {
    context.go(RouteConstants.editProfile);
  }

  // Effacer l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Méthodes pour settings_view.dart
  Future<void> updateNotificationSettings({
    bool? focusNotifications,
    bool? eventNotifications,
  }) async {
    if (state.profile == null) return;

    try {
      final currentSettings = Map<String, dynamic>.from(
        state.profile!.notificationSettings,
      );
      if (focusNotifications != null) {
        currentSettings['focus'] = focusNotifications;
      }
      if (eventNotifications != null) {
        currentSettings['events'] = eventNotifications;
      }

      final updatedProfile = state.profile!.copyWith(
        notificationSettings: currentSettings,
      );

      await _appService.profile.updateProfile(state.profile!.id, updatedProfile.toJson());
      state = state.copyWith(profile: updatedProfile);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateDefaultFocusDuration(int duration) async {
    if (state.profile == null) return;

    try {
      final currentSettings = Map<String, dynamic>.from(
        state.profile!.privacySettings,
      );
      currentSettings['defaultFocusDuration'] = duration;

      final updatedProfile = state.profile!.copyWith(
        privacySettings: currentSettings,
      );

      await _appService.profile.updateProfile(state.profile!.id, updatedProfile.toJson());
      state = state.copyWith(profile: updatedProfile);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateSettings({bool? soundEnabled}) async {
    if (state.profile == null) return;

    try {
      final currentSettings = Map<String, dynamic>.from(
        state.profile!.notificationSettings,
      );
      if (soundEnabled != null) {
        currentSettings['sound'] = soundEnabled;
      }

      final updatedProfile = state.profile!.copyWith(
        notificationSettings: currentSettings,
      );

      await _appService.profile.updateProfile(state.profile!.id, updatedProfile.toJson());
      state = state.copyWith(profile: updatedProfile);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updatePrivacySettings({bool? isPublic, bool? showStats}) async {
    if (state.profile == null) return;

    try {
      final currentSettings = Map<String, dynamic>.from(
        state.profile!.privacySettings,
      );
      if (isPublic != null) {
        currentSettings['isPublic'] = isPublic;
      }
      if (showStats != null) {
        currentSettings['showStats'] = showStats;
      }

      final updatedProfile = state.profile!.copyWith(
        privacySettings: currentSettings,
      );

      await _appService.profile.updateProfile(state.profile!.id, updatedProfile.toJson());
      state = state.copyWith(profile: updatedProfile);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Provider du controller de profil
final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
      final appService = ref.watch(appServiceProvider);
      final authService = ref.watch(authServiceProvider);
      return ProfileController(appService, authService);
    });
