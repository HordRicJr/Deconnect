import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/focus_session.dart';
import '../services/services.dart';
import '../providers/providers.dart';
import '../constants/app_constants.dart';

// État de la session de focus
class FocusSessionState {
  final FocusSession? currentSession;
  final bool isRunning;
  final bool isPaused;
  final Duration elapsed;
  final Duration remaining;
  final List<FocusSession> recentSessions;
  final bool isLoading;
  final String? error;

  const FocusSessionState({
    this.currentSession,
    this.isRunning = false,
    this.isPaused = false,
    this.elapsed = Duration.zero,
    this.remaining = Duration.zero,
    this.recentSessions = const [],
    this.isLoading = false,
    this.error,
  });

  FocusSessionState copyWith({
    FocusSession? currentSession,
    bool? isRunning,
    bool? isPaused,
    Duration? elapsed,
    Duration? remaining,
    List<FocusSession>? recentSessions,
    bool? isLoading,
    String? error,
  }) {
    return FocusSessionState(
      currentSession: currentSession,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      elapsed: elapsed ?? this.elapsed,
      remaining: remaining ?? this.remaining,
      recentSessions: recentSessions ?? this.recentSessions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Controller des sessions de focus
class FocusSessionController extends StateNotifier<FocusSessionState> {
  FocusSessionController(this._appService, this._authService)
    : super(const FocusSessionState());

  final AppService _appService;
  final AuthService _authService;
  Timer? _timer;

  // Démarrer une nouvelle session
  Future<void> startSession({
    required int duration,
    String type = 'pomodoro',
    String? goal,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_authService.isAuthenticated) {
      state = state.copyWith(error: 'Vous devez être connecté');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final userId = _authService.currentUser!.id;

      final session = await _appService.focusSession.startSession(
        userId: userId,
        duration: duration,
        sessionType: type,
        goal: goal,
        metadata: metadata,
      );

      state = state.copyWith(
        currentSession: session,
        isRunning: true,
        isPaused: false,
        elapsed: Duration.zero,
        remaining: Duration(minutes: duration),
        isLoading: false,
      );

      _startTimer();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du démarrage: $e',
      );
    }
  }

  // Mettre en pause la session
  void pauseSession() {
    if (!state.isRunning || state.currentSession == null) return;

    _timer?.cancel();
    state = state.copyWith(isRunning: false, isPaused: true);
  }

  // Reprendre la session
  void resumeSession() {
    if (!state.isPaused || state.currentSession == null) return;

    state = state.copyWith(isRunning: true, isPaused: false);

    _startTimer();
  }

  // Arrêter la session
  Future<void> stopSession() async {
    if (state.currentSession == null) return;

    _timer?.cancel();

    try {
      await _appService.focusSession.endSession(
        state.currentSession!.id,
        'stopped',
      );

      state = state.copyWith(
        currentSession: null,
        isRunning: false,
        isPaused: false,
        elapsed: Duration.zero,
        remaining: Duration.zero,
      );

      await loadRecentSessions();
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de l\'arrêt: $e');
    }
  }

  // Terminer la session avec succès
  Future<void> completeSession() async {
    if (state.currentSession == null) return;

    _timer?.cancel();

    try {
      await _appService.focusSession.endSession(
        state.currentSession!.id,
        'completed',
      );

      // Calculer l'XP gagné
      final xpGained = _calculateXPGained(state.currentSession!);

      state = state.copyWith(
        currentSession: null,
        isRunning: false,
        isPaused: false,
        elapsed: Duration.zero,
        remaining: Duration.zero,
      );

      await loadRecentSessions();

      // Notifier de l'XP gagné (pour affichage dans l'UI)
      _showCompletionReward(xpGained);
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la completion: $e');
    }
  }

  // Charger les sessions récentes
  Future<void> loadRecentSessions() async {
    if (!_authService.isAuthenticated) return;

    try {
      final userId = _authService.currentUser!.id;
      final sessions = await _appService.focusSession.getUserSessions(
        userId,
        limit: 10,
      );

      state = state.copyWith(recentSessions: sessions);
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors du chargement: $e');
    }
  }

  // Charger la session active s'il y en a une
  Future<void> loadActiveSession() async {
    if (!_authService.isAuthenticated) return;

    try {
      final userId = _authService.currentUser!.id;
      final session = await _appService.focusSession.getActiveSession(userId);

      if (session != null) {
        final now = DateTime.now();
        final startTime = session.startedAt ?? session.createdAt;
        final duration = Duration(minutes: session.plannedDuration);
        final elapsed = now.difference(startTime);

        if (elapsed < duration) {
          state = state.copyWith(
            currentSession: session,
            isRunning: true,
            elapsed: elapsed,
            remaining: duration - elapsed,
          );
          _startTimer();
        } else {
          // Session expirée, la terminer automatiquement
          await _appService.focusSession.endSession(session.id, 'expired');
        }
      }
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors du chargement: $e');
    }
  }

  // Obtenir les statistiques de focus
  Future<Map<String, dynamic>> getFocusStats() async {
    if (!_authService.isAuthenticated) return {};

    try {
      final userId = _authService.currentUser!.id;

      // Stats d'aujourd'hui
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final todaySessions = await _appService.focusSession.getUserSessions(
        userId,
        startDate: startOfDay,
        endDate: endOfDay,
      );

      // Stats de la semaine
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final weekSessions = await _appService.focusSession.getUserSessions(
        userId,
        startDate: startOfWeek,
        endDate: today,
      );

      // Streak actuelle
      final streak = await _appService.focusSession.getCurrentStreak(userId);

      return {
        'today_sessions': todaySessions.length,
        'today_minutes': _calculateTotalMinutes(todaySessions),
        'week_sessions': weekSessions.length,
        'week_minutes': _calculateTotalMinutes(weekSessions),
        'current_streak': streak,
        'total_sessions': await _appService.focusSession.getUserSessionsCount(
          userId,
        ),
      };
    } catch (e) {
      return {};
    }
  }

  // Timer interne
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isRunning) {
        timer.cancel();
        return;
      }

      final newElapsed = state.elapsed + const Duration(seconds: 1);
      final sessionDuration = Duration(minutes: state.currentSession!.duration);
      final newRemaining = sessionDuration - newElapsed;

      if (newRemaining <= Duration.zero) {
        // Session terminée automatiquement
        timer.cancel();
        completeSession();
      } else {
        state = state.copyWith(elapsed: newElapsed, remaining: newRemaining);
      }
    });
  }

  // Calculer l'XP gagné
  int _calculateXPGained(FocusSession session) {
    int baseXP = AppConstants.xpFocusSession;

    // Bonus pour les longues sessions
    if (session.duration >= 45) {
      baseXP += 15;
    } else if (session.duration >= 30) {
      baseXP += 10;
    }

    // Bonus streak
    baseXP += (session.duration ~/ 25) * AppConstants.xpStreakBonus;

    return baseXP;
  }

  // Calculer le temps total en minutes
  int _calculateTotalMinutes(List<FocusSession> sessions) {
    return sessions
        .where((s) => s.completedAt != null)
        .map((s) => s.duration)
        .fold(0, (total, duration) => total + duration);
  }

  // Notifier de la récompense (à implémenter dans l'UI)
  void _showCompletionReward(int xp) {
    // Cette méthode sera utilisée par l'UI pour afficher les récompenses
  }

  // Obtenir les sessions prédéfinies
  List<Map<String, dynamic>> getPresetSessions() {
    return [
      {
        'name': 'Pomodoro Court',
        'duration': AppConstants.defaultFocusSessionDuration,
        'type': 'pomodoro',
        'description': '25 minutes de focus intense',
      },
      {
        'name': 'Focus Long',
        'duration': 45,
        'type': 'deep_work',
        'description': '45 minutes de travail profond',
      },
      {
        'name': 'Sprint Rapide',
        'duration': 15,
        'type': 'sprint',
        'description': '15 minutes pour une tâche rapide',
      },
      {
        'name': 'Session Personnalisée',
        'duration': 0,
        'type': 'custom',
        'description': 'Définir votre propre durée',
      },
    ];
  }

  // Effacer l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Provider du controller de focus
final focusSessionControllerProvider =
    StateNotifierProvider<FocusSessionController, FocusSessionState>((ref) {
      final appService = ref.watch(appServiceProvider);
      final authService = ref.watch(authServiceProvider);
      return FocusSessionController(appService, authService);
    });
