import '../models/irl_event.dart';
import 'supabase_service.dart';

class IrlEventService {
  static const String _table = 'irl_events';
  static const String _participantsTable = 'irl_event_participants';
  final SupabaseService _supabase = SupabaseService.instance;

  // Get all events
  Future<List<IrlEvent>> getEvents({
    int? limit,
    String? organizationId,
    String? status,
  }) async {
    try {
      var baseQuery = _supabase.client.from(_table).select();

      List<dynamic> response;

      if (organizationId != null && status != null && limit != null) {
        response = await baseQuery
            .eq('organization_id', organizationId)
            .eq('status', status)
            .order('start_date', ascending: true)
            .limit(limit);
      } else if (organizationId != null && status != null) {
        response = await baseQuery
            .eq('organization_id', organizationId)
            .eq('status', status)
            .order('start_date', ascending: true);
      } else if (organizationId != null && limit != null) {
        response = await baseQuery
            .eq('organization_id', organizationId)
            .order('start_date', ascending: true)
            .limit(limit);
      } else if (status != null && limit != null) {
        response = await baseQuery
            .eq('status', status)
            .order('start_date', ascending: true)
            .limit(limit);
      } else if (organizationId != null) {
        response = await baseQuery
            .eq('organization_id', organizationId)
            .order('start_date', ascending: true);
      } else if (status != null) {
        response = await baseQuery
            .eq('status', status)
            .order('start_date', ascending: true);
      } else if (limit != null) {
        response = await baseQuery
            .order('start_date', ascending: true)
            .limit(limit);
      } else {
        response = await baseQuery.order('start_date', ascending: true);
      }

      return response.map((json) => IrlEvent.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch events: $e');
    }
  }

  // Get upcoming events
  Future<List<IrlEvent>> getUpcomingEvents({
    String? organizationId,
    int? limit,
  }) async {
    try {
      var baseQuery = _supabase.client
          .from(_table)
          .select()
          .gte('start_date', DateTime.now().toIso8601String())
          .eq('status', 'active');

      List<dynamic> response;

      if (organizationId != null && limit != null) {
        response = await baseQuery
            .eq('organization_id', organizationId)
            .order('start_date', ascending: true)
            .limit(limit);
      } else if (organizationId != null) {
        response = await baseQuery
            .eq('organization_id', organizationId)
            .order('start_date', ascending: true);
      } else if (limit != null) {
        response = await baseQuery
            .order('start_date', ascending: true)
            .limit(limit);
      } else {
        response = await baseQuery.order('start_date', ascending: true);
      }

      return response.map((json) => IrlEvent.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch upcoming events: $e');
    }
  }

  // Get event by ID
  Future<IrlEvent?> getEvent(String id) async {
    return await _supabase.selectSingle(_table, IrlEvent.fromJson, id);
  }

  // Create new event
  Future<IrlEvent> createEvent(IrlEvent event) async {
    return await _supabase.insert(_table, IrlEvent.fromJson, event.toJson());
  }

  // Update event
  Future<IrlEvent> updateEvent(String id, Map<String, dynamic> updates) async {
    return await _supabase.update(_table, IrlEvent.fromJson, id, updates);
  }

  // Delete event
  Future<void> deleteEvent(String id) async {
    await _supabase.delete(_table, id);
  }

  // Join event
  Future<void> joinEvent(String eventId, String userId) async {
    try {
      await _supabase.client.from(_participantsTable).insert({
        'event_id': eventId,
        'user_id': userId,
        'status': 'registered',
        'registered_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to join event: $e');
    }
  }

  // Leave event
  Future<void> leaveEvent(String eventId, String userId) async {
    try {
      await _supabase.client
          .from(_participantsTable)
          .delete()
          .eq('event_id', eventId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to leave event: $e');
    }
  }

  // Update participation status
  Future<void> updateParticipationStatus(
    String eventId,
    String userId,
    String status,
  ) async {
    try {
      await _supabase.client
          .from(_participantsTable)
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('event_id', eventId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update participation status: $e');
    }
  }

  // Get event participants
  Future<List<Map<String, dynamic>>> getEventParticipants(
    String eventId, {
    String? status,
  }) async {
    try {
      var baseQuery = _supabase.client
          .from(_participantsTable)
          .select('*, profiles!user_id(id, username, full_name, avatar_url)')
          .eq('event_id', eventId);

      List<dynamic> response;

      if (status != null) {
        response = await baseQuery.eq('status', status);
      } else {
        response = await baseQuery;
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch event participants: $e');
    }
  }

  // Get user's events
  Future<List<IrlEvent>> getUserEvents(String userId, {String? status}) async {
    try {
      var baseQuery = _supabase.client
          .from(_table)
          .select('*, irl_event_participants!inner(user_id, status)')
          .eq('irl_event_participants.user_id', userId);

      List<dynamic> response;

      if (status != null) {
        response = await baseQuery
            .eq('irl_event_participants.status', status)
            .order('start_date', ascending: true);
      } else {
        response = await baseQuery.order('start_date', ascending: true);
      }

      return response.map((json) => IrlEvent.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user events: $e');
    }
  }

  // Check if user is registered for event
  Future<bool> isUserRegistered(String eventId, String userId) async {
    try {
      final response = await _supabase.client
          .from(_participantsTable)
          .select('id')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Search events
  Future<List<IrlEvent>> searchEvents(String query, {int limit = 20}) async {
    try {
      final response = await _supabase.client
          .from(_table)
          .select()
          .or(
            'title.ilike.%$query%,description.ilike.%$query%,location.ilike.%$query%',
          )
          .eq('status', 'active')
          .gte('start_date', DateTime.now().toIso8601String())
          .limit(limit);

      return response.map((json) => IrlEvent.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search events: $e');
    }
  }

  // Get events by date range
  Future<List<IrlEvent>> getEventsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? organizationId,
  }) async {
    try {
      var baseQuery = _supabase.client
          .from(_table)
          .select()
          .gte('start_date', startDate.toIso8601String())
          .lte('end_date', endDate.toIso8601String());

      List<dynamic> response;

      if (organizationId != null) {
        response = await baseQuery
            .eq('organization_id', organizationId)
            .order('start_date', ascending: true);
      } else {
        response = await baseQuery.order('start_date', ascending: true);
      }

      return response.map((json) => IrlEvent.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch events by date range: $e');
    }
  }

  // Check in user to event
  Future<void> checkInUser(String eventId, String userId) async {
    await updateParticipationStatus(eventId, userId, 'attended');
  }

  // Mark user as no-show
  Future<void> markNoShow(String eventId, String userId) async {
    await updateParticipationStatus(eventId, userId, 'no_show');
  }

  // Get event statistics
  Future<Map<String, dynamic>> getEventStats(String eventId) async {
    try {
      final participants = await getEventParticipants(eventId);
      final registered = participants
          .where((p) => p['status'] == 'registered')
          .length;
      final attended = participants
          .where((p) => p['status'] == 'attended')
          .length;
      final noShow = participants.where((p) => p['status'] == 'no_show').length;

      return {
        'total_participants': participants.length,
        'registered': registered,
        'attended': attended,
        'no_show': noShow,
        'attendance_rate': registered > 0
            ? (attended / registered * 100).round()
            : 0,
      };
    } catch (e) {
      throw Exception('Failed to calculate event stats: $e');
    }
  }
}
