import '../models/organization.dart';
import 'supabase_service.dart';

class OrganizationService {
  static const String _table = 'organizations';
  final SupabaseService _supabase = SupabaseService.instance;

  // Get all organizations
  Future<List<Organization>> getOrganizations({int? limit}) async {
    return await _supabase.selectAll(
      _table,
      Organization.fromJson,
      limit: limit,
    );
  }

  // Get organization by ID
  Future<Organization?> getOrganization(String id) async {
    return await _supabase.selectSingle(_table, Organization.fromJson, id);
  }

  // Get organization by code
  Future<Organization?> getOrganizationByCode(String code) async {
    try {
      final response = await _supabase.client
          .from(_table)
          .select()
          .eq('code', code.toLowerCase())
          .maybeSingle();

      return response != null ? Organization.fromJson(response) : null;
    } catch (e) {
      throw Exception('Failed to fetch organization by code: $e');
    }
  }

  // Create new organization
  Future<Organization> createOrganization(Organization organization) async {
    return await _supabase.insert(
      _table,
      Organization.fromJson,
      organization.toJson(),
    );
  }

  // Update organization
  Future<Organization> updateOrganization(
    String id,
    Map<String, dynamic> updates,
  ) async {
    return await _supabase.update(_table, Organization.fromJson, id, updates);
  }

  // Delete organization
  Future<void> deleteOrganization(String id) async {
    await _supabase.delete(_table, id);
  }

  // Get organization stats
  Future<Map<String, dynamic>> getOrganizationStats(
    String organizationId,
  ) async {
    try {
      final response = await _supabase.client.rpc(
        'get_organization_stats',
        params: {'org_id': organizationId},
      );

      return Map<String, dynamic>.from(response);
    } catch (e) {
      // Fallback to manual calculation
      return await _calculateOrganizationStatsManually(organizationId);
    }
  }

  // Get organization leaderboard
  Future<List<Map<String, dynamic>>> getOrganizationLeaderboard(
    String organizationId, {
    int limit = 10,
  }) async {
    try {
      final response = await _supabase.client
          .from('profiles')
          .select(
            'id, username, full_name, avatar_url, total_xp, league_points',
          )
          .eq('organization_id', organizationId)
          .order('league_points', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch organization leaderboard: $e');
    }
  }

  // Join organization
  Future<void> joinOrganization(String userId, String organizationId) async {
    try {
      await _supabase.client
          .from('profiles')
          .update({'organization_id': organizationId})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to join organization: $e');
    }
  }

  // Leave organization
  Future<void> leaveOrganization(String userId) async {
    try {
      await _supabase.client
          .from('profiles')
          .update({'organization_id': null})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Failed to leave organization: $e');
    }
  }

  // Search organizations
  Future<List<Organization>> searchOrganizations(
    String query, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabase.client
          .from(_table)
          .select()
          .or(
            'name.ilike.%$query%,description.ilike.%$query%,code.ilike.%$query%',
          )
          .limit(limit);

      return (response as List)
          .map((json) => Organization.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search organizations: $e');
    }
  }

  // Validate organization code format
  bool isValidOrganizationCode(String code) {
    return RegExp(r'^[a-z0-9]{3,10}$').hasMatch(code.toLowerCase());
  }

  // Check if organization code is available
  Future<bool> isOrganizationCodeAvailable(String code) async {
    final existing = await getOrganizationByCode(code);
    return existing == null;
  }

  // Private helper method
  Future<Map<String, dynamic>> _calculateOrganizationStatsManually(
    String organizationId,
  ) async {
    try {
      // Get member count and basic stats
      final membersResponse = await _supabase.client
          .from('profiles')
          .select('total_xp, league_points')
          .eq('organization_id', organizationId);

      final members = List<Map<String, dynamic>>.from(membersResponse);

      if (members.isEmpty) {
        return {
          'member_count': 0,
          'total_xp': 0,
          'average_xp': 0.0,
          'total_league_points': 0,
          'average_league_points': 0.0,
        };
      }

      final totalXP = members.fold<int>(
        0,
        (sum, member) => sum + (member['total_xp'] as int? ?? 0),
      );
      final totalLeaguePoints = members.fold<int>(
        0,
        (sum, member) => sum + (member['league_points'] as int? ?? 0),
      );

      return {
        'member_count': members.length,
        'total_xp': totalXP,
        'average_xp': totalXP / members.length,
        'total_league_points': totalLeaguePoints,
        'average_league_points': totalLeaguePoints / members.length,
      };
    } catch (e) {
      throw Exception('Failed to calculate organization stats: $e');
    }
  }
}
