import '../models/profile.dart';
import 'supabase_service.dart';

class ProfileService {
  static const String _table = 'profiles';
  final SupabaseService _supabase = SupabaseService.instance;

  // Get current user profile
  Future<Profile?> getCurrentProfile() async {
    final userId = _supabase.currentUserId;
    if (userId == null) return null;

    return await _supabase.selectSingle(_table, Profile.fromJson, userId);
  }

  // Create new profile
  Future<Profile> createProfile(Profile profile) async {
    return await _supabase.insert(_table, Profile.fromJson, profile.toJson());
  }

  // Update profile
  Future<Profile> updateProfile(String id, Map<String, dynamic> updates) async {
    return await _supabase.update(_table, Profile.fromJson, id, updates);
  }

  // Get profile by username
  Future<Profile?> getProfileByUsername(String username) async {
    try {
      final response = await _supabase.client
          .from(_table)
          .select()
          .eq('username', username)
          .maybeSingle();

      return response != null ? Profile.fromJson(response) : null;
    } catch (e) {
      throw Exception('Failed to fetch profile by username: $e');
    }
  }

  // Get organization members
  Future<List<Profile>> getOrganizationMembers(
    String organizationId, {
    int? limit,
  }) async {
    try {
      var query = _supabase.client
          .from(_table)
          .select()
          .eq('organization_id', organizationId)
          .order('created_at');

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return (response as List).map((json) => Profile.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch organization members: $e');
    }
  }

  // Update XP and level
  Future<Profile> addXP(String userId, int xp) async {
    try {
      final response = await _supabase.client.rpc(
        'add_user_xp',
        params: {'user_id': userId, 'xp_to_add': xp},
      );

      return Profile.fromJson(response);
    } catch (e) {
      // Fallback to manual update
      final currentProfile = await _supabase.selectSingle(
        _table,
        Profile.fromJson,
        userId,
      );
      if (currentProfile == null) throw Exception('Profile not found');

      final newXP = currentProfile.totalXp + xp;
      final newLevel = _calculateLevel(newXP);

      return await updateProfile(userId, {
        'total_xp': newXP,
        'level': newLevel,
      });
    }
  }

  // Update league points
  Future<Profile> addLeaguePoints(String userId, int points) async {
    final currentProfile = await _supabase.selectSingle(
      _table,
      Profile.fromJson,
      userId,
    );
    if (currentProfile == null) throw Exception('Profile not found');

    final newPoints = currentProfile.leaguePoints + points;
    final newLeague = _calculateLeague(newPoints);

    return await updateProfile(userId, {
      'league_points': newPoints,
      'league': newLeague,
    });
  }

  // Update avatar health
  Future<Profile> updateAvatarHealth(String userId, double healthDelta) async {
    final currentProfile = await _supabase.selectSingle(
      _table,
      Profile.fromJson,
      userId,
    );
    if (currentProfile == null) throw Exception('Profile not found');

    final newHealth = (currentProfile.avatarHealth + healthDelta).clamp(
      0.0,
      1.0,
    );

    return await updateProfile(userId, {'avatar_health': newHealth});
  }

  // Get leaderboard
  Future<List<Profile>> getLeaderboard({String? league, int limit = 50}) async {
    try {
      if (league != null) {
        final response = await _supabase.client
            .from(_table)
            .select()
            .eq('league', league)
            .order('league_points', ascending: false)
            .limit(limit);
        return (response as List)
            .map((json) => Profile.fromJson(json))
            .toList();
      } else {
        final response = await _supabase.client
            .from(_table)
            .select()
            .order('league_points', ascending: false)
            .limit(limit);
        return (response as List)
            .map((json) => Profile.fromJson(json))
            .toList();
      }
    } catch (e) {
      throw Exception('Failed to fetch leaderboard: $e');
    }
  }

  // Search profiles
  Future<List<Profile>> searchProfiles(String query, {int limit = 20}) async {
    try {
      final response = await _supabase.client
          .from(_table)
          .select()
          .or('username.ilike.%$query%,full_name.ilike.%$query%')
          .limit(limit);

      return (response as List).map((json) => Profile.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search profiles: $e');
    }
  }

  // Private helper methods
  int _calculateLevel(int totalXP) {
    return (totalXP / 100).floor() + 1;
  }

  String _calculateLeague(int points) {
    if (points >= 10000) return 'legendary';
    if (points >= 5000) return 'diamond';
    if (points >= 2500) return 'platinum';
    if (points >= 1000) return 'gold';
    if (points >= 300) return 'silver';
    return 'bronze';
  }
}
