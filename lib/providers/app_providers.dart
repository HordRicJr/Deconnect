import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../models/profile.dart';
import '../models/organization.dart';
import '../models/challenge.dart';
import '../models/user_challenge.dart';
import '../models/focus_session.dart';
import '../models/irl_event.dart';
import '../services/services.dart';

// App service provider
final appServiceProvider = Provider<AppService>((ref) {
  return AppService.instance;
});

// Authentication state provider
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Current user profile provider
final currentUserProfileProvider = FutureProvider<Profile?>((ref) async {
  final appService = ref.read(appServiceProvider);
  if (!appService.isAuthenticated) return null;

  return await appService.profile.getCurrentProfile();
});

// User dashboard data provider
final dashboardDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final appService = ref.read(appServiceProvider);
  if (!appService.isAuthenticated) throw Exception('User not authenticated');

  return await appService.getUserDashboardData();
});

// Active focus session provider
final activeFocusSessionProvider = FutureProvider<FocusSession?>((ref) async {
  final appService = ref.read(appServiceProvider);
  final userId = appService.currentUserId;
  if (userId == null) return null;

  return await appService.focusSession.getActiveSession(userId);
});

// User challenges provider
final userChallengesProvider =
    FutureProvider.family<List<UserChallenge>, String?>((ref, status) async {
      final appService = ref.read(appServiceProvider);
      final userId = appService.currentUserId;
      if (userId == null) return [];

      return await appService.challenge.getUserChallenges(
        userId,
        status: status,
      );
    });

// Active challenges provider
final activeChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  final appService = ref.read(appServiceProvider);
  return await appService.challenge.getActiveChallenges(limit: 20);
});

// Upcoming events provider
final upcomingEventsProvider = FutureProvider<List<IrlEvent>>((ref) async {
  final appService = ref.read(appServiceProvider);
  return await appService.irlEvent.getUpcomingEvents(limit: 10);
});

// User events provider
final userEventsProvider = FutureProvider<List<IrlEvent>>((ref) async {
  final appService = ref.read(appServiceProvider);
  final userId = appService.currentUserId;
  if (userId == null) return [];

  return await appService.irlEvent.getUserEvents(userId);
});

// Organization provider
final organizationProvider = FutureProvider.family<Organization?, String?>((
  ref,
  organizationId,
) async {
  if (organizationId == null) return null;

  final appService = ref.read(appServiceProvider);
  return await appService.organization.getOrganization(organizationId);
});

// Organization members provider
final organizationMembersProvider =
    FutureProvider.family<List<Profile>, String>((ref, organizationId) async {
      final appService = ref.read(appServiceProvider);
      return await appService.profile.getOrganizationMembers(
        organizationId,
        limit: 50,
      );
    });

// Focus session stats provider
final focusSessionStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final appService = ref.read(appServiceProvider);
  final userId = appService.currentUserId;
  if (userId == null) return {};

  return await appService.focusSession.getMonthlyStats(userId);
});

// Challenge stats provider
final challengeStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final appService = ref.read(appServiceProvider);
  final userId = appService.currentUserId;
  if (userId == null) return {};

  return await appService.challenge.getUserChallengeStats(userId);
});

// App statistics provider
final appStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final appService = ref.read(appServiceProvider);
  return await appService.getAppStats();
});

// Leaderboard provider
final leaderboardProvider = FutureProvider.family<List<Profile>, String?>((
  ref,
  league,
) async {
  final appService = ref.read(appServiceProvider);
  return await appService.profile.getLeaderboard(league: league, limit: 50);
});

// Search results providers
final searchProfilesProvider = FutureProvider.family<List<Profile>, String>((
  ref,
  query,
) async {
  if (query.isEmpty) return [];

  final appService = ref.read(appServiceProvider);
  return await appService.profile.searchProfiles(query);
});

final searchChallengesProvider = FutureProvider.family<List<Challenge>, String>(
  (ref, query) async {
    if (query.isEmpty) return [];

    final appService = ref.read(appServiceProvider);
    return await appService.challenge.searchChallenges(query);
  },
);

final searchEventsProvider = FutureProvider.family<List<IrlEvent>, String>((
  ref,
  query,
) async {
  if (query.isEmpty) return [];

  final appService = ref.read(appServiceProvider);
  return await appService.irlEvent.searchEvents(query);
});

final searchOrganizationsProvider =
    FutureProvider.family<List<Organization>, String>((ref, query) async {
      if (query.isEmpty) return [];

      final appService = ref.read(appServiceProvider);
      return await appService.organization.searchOrganizations(query);
    });

// Session timer state provider
class SessionTimerNotifier extends StateNotifier<Map<String, dynamic>?> {
  SessionTimerNotifier() : super(null);

  void startSession(FocusSession session) {
    state = {
      'session': session,
      'start_time': DateTime.now(),
      'is_running': true,
      'is_paused': false,
    };
  }

  void pauseSession() {
    if (state != null) {
      state = {...state!, 'is_paused': true, 'is_running': false};
    }
  }

  void resumeSession() {
    if (state != null) {
      state = {...state!, 'is_paused': false, 'is_running': true};
    }
  }

  void stopSession() {
    state = null;
  }

  Duration? get elapsed {
    if (state == null) return null;
    final startTime = state!['start_time'] as DateTime;
    return DateTime.now().difference(startTime);
  }

  bool get isRunning => state?['is_running'] ?? false;
  bool get isPaused => state?['is_paused'] ?? false;
}

final sessionTimerProvider =
    StateNotifierProvider<SessionTimerNotifier, Map<String, dynamic>?>((ref) {
      return SessionTimerNotifier();
    });

// === New Services Providers ===

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

// API service provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService.instance;
});

// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [], // Routes will be defined in app_router.dart
  );
});

// Authentication status provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isAuthenticated && authService.isTokenValid;
});

// Current session provider
final currentSessionProvider = Provider<Session?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentSession;
});

// User profile with auth integration
final authenticatedProfileProvider = FutureProvider<Profile?>((ref) async {
  final authService = ref.read(authServiceProvider);
  if (!authService.isAuthenticated) return null;

  return await authService.getUserProfile();
});

// Storage upload progress provider
final uploadProgressProvider = StateProvider<double>((ref) => 0.0);

// Cache management provider
final cacheProvider = Provider((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return CacheManager(storageService);
});

// Network status provider (for API service)
final networkStatusProvider = StateProvider<bool>((ref) => true);

// API loading states
final apiLoadingProvider = StateProvider<Map<String, bool>>((ref) => {});

// Error handling provider
final errorProvider = StateProvider<String?>((ref) => null);

// Cache manager class
class CacheManager {
  final StorageService _storageService;

  CacheManager(this._storageService);

  Future<void> clearAll() => _storageService.clearCache();

  Future<String?> get(String key) => _storageService.loadFromCache(key);

  Future<void> set(String key, String value) =>
      _storageService.saveToCache(key, value);

  Future<bool> remove(String key) => _storageService.deleteFromCache(key);
}
