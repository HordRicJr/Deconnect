import 'supabase_service.dart';
import 'profile_service.dart';
import 'organization_service.dart';
import 'challenge_service.dart';
import 'focus_session_service.dart';
import 'irl_event_service.dart';

// Main service orchestrator
class AppService {
  static AppService? _instance;
  static AppService get instance => _instance ??= AppService._();

  AppService._();

  // Service instances
  final SupabaseService supabase = SupabaseService.instance;
  final ProfileService profile = ProfileService();
  final OrganizationService organization = OrganizationService();
  final ChallengeService challenge = ChallengeService();
  final FocusSessionService focusSession = FocusSessionService();
  final IrlEventService irlEvent = IrlEventService();

  // Initialize all services
  Future<void> initialize() async {
    await supabase.initialize();
  }

  // Authentication shortcuts
  bool get isAuthenticated => supabase.isAuthenticated;
  String? get currentUserId => supabase.currentUserId;

  // Sign in
  Future<void> signIn(String email, String password) async {
    await supabase.signIn(email, password);
  }

  // Sign up
  Future<void> signUp(
    String email,
    String password, {
    Map<String, dynamic>? metadata,
  }) async {
    await supabase.signUp(email, password, data: metadata);
  }

  // Sign out
  Future<void> signOut() async {
    await supabase.signOut();
  }

  // Complete user onboarding flow
  Future<void> completeOnboarding({
    required String username,
    required String fullName,
    String? organizationCode,
    String? avatarUrl,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Check if organization exists
    String? organizationId;
    if (organizationCode != null && organizationCode.isNotEmpty) {
      final org = await organization.getOrganizationByCode(organizationCode);
      organizationId = org?.id;
    }

    // Create user profile
    final profileData = {
      'id': userId,
      'username': username,
      'full_name': fullName,
      'organization_id': organizationId,
      'avatar_url': avatarUrl,
      'total_xp': 0,
      'level': 1,
      'league_points': 0,
      'league': 'bronze',
      'avatar_health': 1.0,
      'streak_count': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await supabase.client.from('profiles').insert(profileData);
  }

  // Get user dashboard data
  Future<Map<String, dynamic>> getUserDashboardData() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Run all queries in parallel
    final futures = await Future.wait([
      profile.getCurrentProfile(),
      challenge.getUserChallenges(userId, status: 'in_progress'),
      focusSession.getTodaySessions(userId),
      focusSession.getActiveSession(userId),
      irlEvent.getUserEvents(userId),
    ]);

    final userProfile = futures[0];
    final activeChallenges = futures[1] as List;
    final todaySessions = futures[2] as List;
    final activeSession = futures[3];
    final userEvents = futures[4] as List;

    return {
      'profile': userProfile,
      'active_challenges': activeChallenges,
      'today_sessions': todaySessions,
      'active_session': activeSession,
      'upcoming_events': userEvents,
    };
  }

  // Award XP for completing tasks
  Future<void> awardXP({
    required int xp,
    required String source,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Update user XP
    await profile.addXP(userId, xp);

    // Log XP award
    await supabase.client.from('xp_logs').insert({
      'user_id': userId,
      'xp_amount': xp,
      'source': source,
      'metadata': metadata,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // Complete focus session with XP award
  Future<void> completeFocusSessionWithReward(String sessionId) async {
    final session = await focusSession.getFocusSession(sessionId);
    if (session == null) throw Exception('Session not found');

    // Complete the session
    await focusSession.completeFocusSession(sessionId, wasSuccessful: true);

    // Calculate XP based on session duration
    final actualDuration = session.startedAt != null
        ? DateTime.now().difference(session.startedAt!).inMinutes
        : session.plannedDuration;
    final xpReward = (actualDuration * 2).clamp(10, 100);

    // Award XP
    await awardXP(
      xp: xpReward,
      source: 'focus_session',
      metadata: {
        'session_id': sessionId,
        'duration_minutes': actualDuration,
        'session_type': session.sessionType,
      },
    );
  }

  // Complete challenge with rewards
  Future<void> completeChallengeWithReward(String challengeId) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final challengeData = await challenge.getChallenge(challengeId);
    if (challengeData == null) throw Exception('Challenge not found');

    // Complete the challenge
    await challenge.completeChallenge(userId, challengeId);

    // Award XP and league points
    await awardXP(
      xp: challengeData.xpReward,
      source: 'challenge_completion',
      metadata: {
        'challenge_id': challengeId,
        'challenge_title': challengeData.title,
        'difficulty': challengeData.difficulty,
      },
    );

    if (challengeData.leaguePointsReward > 0) {
      await profile.addLeaguePoints(userId, challengeData.leaguePointsReward);
    }
  }

  // Get app statistics
  Future<Map<String, dynamic>> getAppStats() async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final futures = await Future.wait([
      focusSession.getMonthlyStats(userId),
      challenge.getUserChallengeStats(userId),
      focusSession.getSessionStreak(userId),
    ]);

    return {
      'focus_stats': futures[0],
      'challenge_stats': futures[1],
      'current_streak': futures[2],
    };
  }

  // Sync offline data (placeholder for future implementation)
  Future<void> syncOfflineData() async {
    // Implementation for offline data synchronization
    // This would handle uploading any cached data when connection is restored
  }

  // Handle deep links and notifications
  Future<void> handleDeepLink(String link) async {
    // Implementation for handling deep links
    // e.g., challenge invites, event registrations, etc.
  }
}
