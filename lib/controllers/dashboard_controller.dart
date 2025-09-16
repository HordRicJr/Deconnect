import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profile.dart';
import '../models/focus_session.dart';
import '../models/challenge.dart';
import '../models/user_challenge.dart';
import '../models/irl_event.dart';
import '../services/services.dart';
import '../providers/providers.dart';

// Données du tableau de bord
class DashboardData {
  final Profile? profile;
  final List<FocusSession> recentSessions;
  final List<UserChallenge> activeChallenges;
  final List<IrlEvent> upcomingEvents;
  final Map<String, dynamic> stats;

  const DashboardData({
    this.profile,
    this.recentSessions = const [],
    this.activeChallenges = const [],
    this.upcomingEvents = const [],
    this.stats = const {},
  });
}

// État du tableau de bord
class DashboardState {
  final DashboardData? data;
  final bool isLoading;
  final String? error;
  final DateTime lastRefresh;

  const DashboardState({
    this.data,
    this.isLoading = false,
    this.error,
    required this.lastRefresh,
  });

  DashboardState copyWith({
    DashboardData? data,
    bool? isLoading,
    String? error,
    DateTime? lastRefresh,
  }) {
    return DashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastRefresh: lastRefresh ?? this.lastRefresh,
    );
  }
}

// Extensions pour les getters manquants
extension DashboardStateExtensions on DashboardState {
  Map<String, dynamic>? get stats => data?.stats;
  List<IrlEvent> get upcomingEvents => data?.upcomingEvents ?? [];
  List<FocusSession> get recentActivities => data?.recentSessions ?? [];
}

// Controller du tableau de bord
class DashboardController extends StateNotifier<DashboardState> {
  DashboardController(this._appService, this._authService)
    : super(DashboardState(lastRefresh: DateTime.now()));

  final AppService _appService;
  final AuthService _authService;

  // Charger toutes les données du dashboard
  Future<void> loadDashboardData() async {
    if (!_authService.isAuthenticated) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final userId = _authService.currentUser!.id;

      // Charger les données en parallèle
      final results = await Future.wait([
        _authService.getUserProfile(),
        _appService.focusSession.getUserSessions(userId, limit: 5),
        _appService.challenge.getUserChallenges(userId, status: 'active'),
        _appService.irlEvent.getUpcomingEvents(limit: 3),
        _calculateUserStats(userId),
      ]);

      final dashboardData = DashboardData(
        profile: results[0] as Profile?,
        recentSessions: results[1] as List<FocusSession>,
        activeChallenges: results[2] as List<UserChallenge>,
        upcomingEvents: results[3] as List<IrlEvent>,
        stats: results[4] as Map<String, dynamic>,
      );

      state = state.copyWith(
        data: dashboardData,
        isLoading: false,
        lastRefresh: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des données: $e',
      );
    }
  }

  // Rafraîchir les données
  Future<void> refreshData() async {
    // Vérifier si on doit rafraîchir (éviter les rafraîchissements trop fréquents)
    final now = DateTime.now();
    if (now.difference(state.lastRefresh).inMinutes < 2 && state.data != null) {
      return;
    }

    await loadDashboardData();
  }

  // Calculer les statistiques utilisateur
  Future<Map<String, dynamic>> _calculateUserStats(String userId) async {
    try {
      // Statistiques des sessions de focus
      final totalSessions = await _appService.focusSession.getUserSessionsCount(
        userId,
      );
      final todaySessions = await _appService.focusSession.getUserSessions(
        userId,
        startDate: DateTime.now().copyWith(hour: 0, minute: 0, second: 0),
        endDate: DateTime.now().copyWith(hour: 23, minute: 59, second: 59),
      );

      // Statistiques des défis
      final completedChallenges = await _appService.challenge.getUserChallenges(
        userId,
        status: 'completed',
      );

      // XP et niveau actuel
      final profile = await _authService.getUserProfile();
      final currentXP = profile?.experience ?? 0;
      final currentLevel = profile?.level ?? 1;

      return {
        'total_sessions': totalSessions,
        'today_sessions': todaySessions.length,
        'total_focus_time': _calculateTotalFocusTime(todaySessions),
        'completed_challenges': completedChallenges.length,
        'current_xp': currentXP,
        'current_level': currentLevel,
        'streak': await _calculateStreak(userId),
      };
    } catch (e) {
      return {};
    }
  }

  // Calculer le temps total de focus
  int _calculateTotalFocusTime(List<FocusSession> sessions) {
    return sessions
        .where((session) => session.completedAt != null)
        .map((session) => session.duration)
        .fold(0, (total, duration) => total + duration);
  }

  // Calculer la streak
  Future<int> _calculateStreak(String userId) async {
    try {
      return await _appService.focusSession.getCurrentStreak(userId);
    } catch (e) {
      return 0;
    }
  }

  // Démarrer une session de focus rapide
  Future<void> startQuickFocusSession(int duration) async {
    if (!_authService.isAuthenticated) return;

    try {
      final userId = _authService.currentUser!.id;
      await _appService.focusSession.startSession(
        userId: userId,
        duration: duration,
        sessionType: 'pomodoro',
      );

      // Rafraîchir les données après le démarrage
      await refreshData();
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur lors du démarrage de la session: $e',
      );
    }
  }

  // Rejoindre un défi
  Future<void> joinChallenge(String challengeId) async {
    if (!_authService.isAuthenticated) return;

    try {
      final userId = _authService.currentUser!.id;
      await _appService.challenge.joinChallenge(challengeId, userId);

      // Rafraîchir les données
      await refreshData();
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur lors de l\'inscription au défi: $e',
      );
    }
  }

  // S'inscrire à un événement
  Future<void> joinEvent(String eventId) async {
    if (!_authService.isAuthenticated) return;

    try {
      final userId = _authService.currentUser!.id;
      await _appService.irlEvent.joinEvent(eventId, userId);

      // Rafraîchir les données
      await refreshData();
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur lors de l\'inscription à l\'événement: $e',
      );
    }
  }

  // Effacer l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider du controller du dashboard
final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
      final appService = ref.watch(appServiceProvider);
      final authService = ref.watch(authServiceProvider);
      return DashboardController(appService, authService);
    });
