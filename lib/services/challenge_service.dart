import '../models/challenge.dart';
import '../models/user_challenge.dart';
import 'supabase_service.dart';

class ChallengeService {
  static const String _table = 'challenges';
  static const String _userChallengeTable = 'user_challenges';
  final SupabaseService _supabase = SupabaseService.instance;

  // Get all active challenges
  Future<List<Challenge>> getActiveChallenges({int? limit}) async {
    try {
      var query = _supabase.client
          .from(_table)
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return (response as List)
          .map((json) => Challenge.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch active challenges: $e');
    }
  }

  // Get challenges by category
  Future<List<Challenge>> getChallengesByCategory(
    String category, {
    int? limit,
  }) async {
    try {
      var query = _supabase.client
          .from(_table)
          .select()
          .eq('category', category)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return (response as List)
          .map((json) => Challenge.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch challenges by category: $e');
    }
  }

  // Get challenge by ID
  Future<Challenge?> getChallenge(String id) async {
    return await _supabase.selectSingle(_table, Challenge.fromJson, id);
  }

  // Create new challenge
  Future<Challenge> createChallenge(Challenge challenge) async {
    return await _supabase.insert(
      _table,
      Challenge.fromJson,
      challenge.toJson(),
    );
  }

  // Update challenge
  Future<Challenge> updateChallenge(
    String id,
    Map<String, dynamic> updates,
  ) async {
    return await _supabase.update(_table, Challenge.fromJson, id, updates);
  }

  // Delete challenge
  Future<void> deleteChallenge(String id) async {
    await _supabase.delete(_table, id);
  }

  // Get user's challenges
  Future<List<UserChallenge>> getUserChallenges(
    String userId, {
    String? status,
  }) async {
    try {
      var baseQuery = _supabase.client
          .from(_userChallengeTable)
          .select('*, challenge:challenges(*)')
          .eq('user_id', userId);

      List<dynamic> response;

      if (status != null) {
        response = await baseQuery
            .eq('status', status)
            .order('created_at', ascending: false);
      } else {
        response = await baseQuery.order('created_at', ascending: false);
      }
      return response.map((json) => UserChallenge.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user challenges: $e');
    }
  }

  // Join challenge
  Future<UserChallenge> joinChallenge(String userId, String challengeId) async {
    final userChallenge = UserChallenge(
      id: '', // Will be set by database
      userId: userId,
      challengeId: challengeId,
      status: 'in_progress',
      progress: const {},
      assignedAt: DateTime.now(),
      startedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    return await _supabase.insert(
      _userChallengeTable,
      UserChallenge.fromJson,
      userChallenge.toJson(),
    );
  }

  // Update challenge progress
  Future<UserChallenge> updateChallengeProgress(
    String userId,
    String challengeId,
    int progress,
  ) async {
    try {
      final challenge = await getChallenge(challengeId);
      if (challenge == null) throw Exception('Challenge not found');

      String status = 'in_progress';
      DateTime? completedAt;

      // Use difficulty as target (can be customized later)
      final targetValue =
          challenge.content['target_value'] as int? ??
          challenge.difficulty * 10;
      if (progress >= targetValue) {
        status = 'completed';
        completedAt = DateTime.now();
      }

      final response = await _supabase.client
          .from(_userChallengeTable)
          .update({
            'progress': progress,
            'status': status,
            'completed_at': completedAt?.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('challenge_id', challengeId)
          .select()
          .single();

      return UserChallenge.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update challenge progress: $e');
    }
  }

  // Complete challenge
  Future<UserChallenge> completeChallenge(
    String userId,
    String challengeId,
  ) async {
    try {
      final response = await _supabase.client
          .from(_userChallengeTable)
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('challenge_id', challengeId)
          .select()
          .single();

      return UserChallenge.fromJson(response);
    } catch (e) {
      throw Exception('Failed to complete challenge: $e');
    }
  }

  // Get challenge leaderboard
  Future<List<Map<String, dynamic>>> getChallengeLeaderboard(
    String challengeId, {
    int limit = 10,
  }) async {
    try {
      final response = await _supabase.client
          .from(_userChallengeTable)
          .select(
            'progress, user_id, profiles!user_id(username, full_name, avatar_url)',
          )
          .eq('challenge_id', challengeId)
          .order('progress', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch challenge leaderboard: $e');
    }
  }

  // Get weekly challenges
  Future<List<Challenge>> getWeeklyChallenges() async {
    final weekStart = DateTime.now().subtract(
      Duration(days: DateTime.now().weekday - 1),
    );
    final weekEnd = weekStart.add(Duration(days: 6));

    try {
      final response = await _supabase.client
          .from(_table)
          .select()
          .eq('is_active', true)
          .gte('created_at', weekStart.toIso8601String())
          .lte('created_at', weekEnd.toIso8601String())
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Challenge.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch weekly challenges: $e');
    }
  }

  // Search challenges
  Future<List<Challenge>> searchChallenges(
    String query, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabase.client
          .from(_table)
          .select()
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .eq('is_active', true)
          .limit(limit);

      return (response as List)
          .map((json) => Challenge.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search challenges: $e');
    }
  }

  // Get recommended challenges for user
  Future<List<Challenge>> getRecommendedChallenges(
    String userId, {
    int limit = 5,
  }) async {
    try {
      // Get challenges user hasn't joined yet
      final response = await _supabase.client
          .from(_table)
          .select()
          .eq('is_active', true)
          .not(
            'id',
            'in',
            '(SELECT challenge_id FROM user_challenges WHERE user_id = $userId)',
          )
          .order('difficulty')
          .limit(limit);

      return (response as List)
          .map((json) => Challenge.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recommended challenges: $e');
    }
  }

  // Check if user has joined challenge
  Future<bool> hasUserJoinedChallenge(String userId, String challengeId) async {
    try {
      final response = await _supabase.client
          .from(_userChallengeTable)
          .select('id')
          .eq('user_id', userId)
          .eq('challenge_id', challengeId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Get user challenge stats
  Future<Map<String, dynamic>> getUserChallengeStats(String userId) async {
    try {
      final response = await _supabase.client.rpc(
        'get_user_challenge_stats',
        params: {'user_id': userId},
      );

      return Map<String, dynamic>.from(response);
    } catch (e) {
      // Fallback to manual calculation
      return await _calculateUserChallengeStatsManually(userId);
    }
  }

  // Private helper method
  Future<Map<String, dynamic>> _calculateUserChallengeStatsManually(
    String userId,
  ) async {
    try {
      final response = await _supabase.client
          .from(_userChallengeTable)
          .select('status')
          .eq('user_id', userId);

      final challenges = List<Map<String, dynamic>>.from(response);

      final total = challenges.length;
      final completed = challenges
          .where((c) => c['status'] == 'completed')
          .length;
      final inProgress = challenges
          .where((c) => c['status'] == 'in_progress')
          .length;
      final failed = challenges.where((c) => c['status'] == 'failed').length;

      return {
        'total_challenges': total,
        'completed_challenges': completed,
        'in_progress_challenges': inProgress,
        'failed_challenges': failed,
        'completion_rate': total > 0 ? (completed / total * 100).round() : 0,
      };
    } catch (e) {
      throw Exception('Failed to calculate user challenge stats: $e');
    }
  }

  // Quitter un défi
  Future<void> leaveChallenge(String challengeId, String userId) async {
    try {
      await _supabase.client
          .from(_userChallengeTable)
          .delete()
          .eq('challenge_id', challengeId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to leave challenge: $e');
    }
  }

  // Mettre à jour un défi utilisateur
  Future<void> updateUserChallenge(
    String challengeId,
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _supabase.client
          .from(_userChallengeTable)
          .update(updates)
          .eq('challenge_id', challengeId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update user challenge: $e');
    }
  }
}
