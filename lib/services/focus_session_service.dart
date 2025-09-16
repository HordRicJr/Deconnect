import '../models/focus_session.dart';
import 'supabase_service.dart';

class FocusSessionService {
  static const String _table = 'focus_sessions';
  final SupabaseService _supabase = SupabaseService.instance;

  // Get user's focus sessions
  Future<List<FocusSession>> getUserFocusSessions(
    String userId, {
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var baseQuery = _supabase.client
          .from(_table)
          .select()
          .eq('user_id', userId);

      List<dynamic> response;

      if (startDate != null && endDate != null && limit != null) {
        response = await baseQuery
            .gte('started_at', startDate.toIso8601String())
            .lte('started_at', endDate.toIso8601String())
            .order('started_at', ascending: false)
            .limit(limit);
      } else if (startDate != null && endDate != null) {
        response = await baseQuery
            .gte('started_at', startDate.toIso8601String())
            .lte('started_at', endDate.toIso8601String())
            .order('started_at', ascending: false);
      } else if (startDate != null && limit != null) {
        response = await baseQuery
            .gte('started_at', startDate.toIso8601String())
            .order('started_at', ascending: false)
            .limit(limit);
      } else if (endDate != null && limit != null) {
        response = await baseQuery
            .lte('started_at', endDate.toIso8601String())
            .order('started_at', ascending: false)
            .limit(limit);
      } else if (startDate != null) {
        response = await baseQuery
            .gte('started_at', startDate.toIso8601String())
            .order('started_at', ascending: false);
      } else if (endDate != null) {
        response = await baseQuery
            .lte('started_at', endDate.toIso8601String())
            .order('started_at', ascending: false);
      } else if (limit != null) {
        response = await baseQuery
            .order('started_at', ascending: false)
            .limit(limit);
      } else {
        response = await baseQuery.order('started_at', ascending: false);
      }
      return response.map((json) => FocusSession.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch focus sessions: $e');
    }
  }

  // Get focus session by ID
  Future<FocusSession?> getFocusSession(String id) async {
    return await _supabase.selectSingle(_table, FocusSession.fromJson, id);
  }

  // Create new focus session
  Future<FocusSession> createFocusSession(FocusSession session) async {
    return await _supabase.insert(
      _table,
      FocusSession.fromJson,
      session.toJson(),
    );
  }

  // Start a focus session
  Future<FocusSession> startFocusSession({
    required String userId,
    required int plannedDuration,
    String? sessionType,
    Map<String, dynamic>? metadata,
  }) async {
    final session = FocusSession(
      id: '', // Will be set by database
      userId: userId,
      startedAt: DateTime.now(),
      plannedDuration: plannedDuration,
      sessionType: sessionType ?? 'pomodoro',
      status: 'active',
      contextData: metadata ?? {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await createFocusSession(session);
  }

  // Complete focus session
  Future<FocusSession> completeFocusSession(
    String sessionId, {
    bool wasSuccessful = true,
  }) async {
    final session = await getFocusSession(sessionId);
    if (session == null) throw Exception('Focus session not found');

    final actualDuration = session.startedAt != null
        ? DateTime.now().difference(session.startedAt!).inMinutes
        : session.plannedDuration;

    try {
      final response = await _supabase.client
          .from(_table)
          .update({
            'ended_at': DateTime.now().toIso8601String(),
            'actual_duration': actualDuration,
            'status': wasSuccessful ? 'completed' : 'failed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId)
          .select()
          .single();

      return FocusSession.fromJson(response);
    } catch (e) {
      throw Exception('Failed to complete focus session: $e');
    }
  }

  // Pause focus session
  Future<FocusSession> pauseFocusSession(String sessionId) async {
    try {
      final response = await _supabase.client
          .from(_table)
          .update({
            'status': 'paused',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId)
          .select()
          .single();

      return FocusSession.fromJson(response);
    } catch (e) {
      throw Exception('Failed to pause focus session: $e');
    }
  }

  // Resume focus session
  Future<FocusSession> resumeFocusSession(String sessionId) async {
    try {
      final response = await _supabase.client
          .from(_table)
          .update({
            'status': 'active',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId)
          .select()
          .single();

      return FocusSession.fromJson(response);
    } catch (e) {
      throw Exception('Failed to resume focus session: $e');
    }
  }

  // Cancel focus session
  Future<FocusSession> cancelFocusSession(String sessionId) async {
    final session = await getFocusSession(sessionId);
    if (session == null) throw Exception('Focus session not found');

    try {
      final response = await _supabase.client
          .from(_table)
          .update({
            'ended_at': DateTime.now().toIso8601String(),
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId)
          .select()
          .single();

      return FocusSession.fromJson(response);
    } catch (e) {
      throw Exception('Failed to cancel focus session: $e');
    }
  }

  // Get active session for user
  Future<FocusSession?> getActiveSession(String userId) async {
    try {
      final response = await _supabase.client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .inFilter('status', ['active', 'paused'])
          .order('started_at', ascending: false)
          .maybeSingle();

      return response != null ? FocusSession.fromJson(response) : null;
    } catch (e) {
      throw Exception('Failed to fetch active session: $e');
    }
  }

  // Get today's sessions
  Future<List<FocusSession>> getTodaySessions(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    return await getUserFocusSessions(
      userId,
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  // Get session statistics
  Future<Map<String, dynamic>> getSessionStats(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final sessions = await getUserFocusSessions(
        userId,
        startDate: startDate,
        endDate: endDate,
      );

      final totalSessions = sessions.length;
      final completedSessions = sessions
          .where((s) => s.status == 'completed')
          .length;
      final totalMinutes = sessions
          .where((s) => s.actualDuration != null)
          .fold<int>(0, (sum, s) => sum + s.actualDuration!);

      final averageSession = completedSessions > 0
          ? totalMinutes / completedSessions
          : 0.0;

      final successRate = totalSessions > 0
          ? (completedSessions / totalSessions * 100).round()
          : 0;

      // Group by session type
      final sessionTypes = <String, int>{};
      for (final session in sessions) {
        final type = session.sessionType;
        sessionTypes[type] = (sessionTypes[type] ?? 0) + 1;
      }

      return {
        'total_sessions': totalSessions,
        'completed_sessions': completedSessions,
        'total_minutes': totalMinutes,
        'average_session_minutes': averageSession,
        'success_rate': successRate,
        'session_types': sessionTypes,
      };
    } catch (e) {
      throw Exception('Failed to calculate session stats: $e');
    }
  }

  // Get weekly statistics
  Future<Map<String, dynamic>> getWeeklyStats(String userId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));

    return await getSessionStats(
      userId,
      startDate: startOfWeek,
      endDate: endOfWeek,
    );
  }

  // Get monthly statistics
  Future<Map<String, dynamic>> getMonthlyStats(String userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(
      now.year,
      now.month + 1,
      1,
    ).subtract(Duration(days: 1));

    return await getSessionStats(
      userId,
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }

  // Get session streak
  Future<int> getSessionStreak(String userId) async {
    try {
      final response = await _supabase.client.rpc(
        'get_focus_session_streak',
        params: {'user_id': userId},
      );

      return response as int? ?? 0;
    } catch (e) {
      // Fallback to manual calculation
      return await _calculateStreakManually(userId);
    }
  }

  // Update session metadata
  Future<FocusSession> updateSessionMetadata(
    String sessionId,
    Map<String, dynamic> metadata,
  ) async {
    try {
      final response = await _supabase.client
          .from(_table)
          .update({
            'metadata': metadata,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId)
          .select()
          .single();

      return FocusSession.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update session metadata: $e');
    }
  }

  // Get best session streak
  Future<int> getBestStreak(String userId) async {
    try {
      final response = await _supabase.client.rpc(
        'get_best_focus_streak',
        params: {'user_id': userId},
      );

      return response as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Private helper method
  Future<int> _calculateStreakManually(String userId) async {
    try {
      final sessions = await getUserFocusSessions(userId, limit: 30);

      int streak = 0;
      DateTime? lastSessionDate;

      for (final session in sessions.reversed) {
        if (session.status == 'completed' && session.startedAt != null) {
          final sessionDate = DateTime(
            session.startedAt!.year,
            session.startedAt!.month,
            session.startedAt!.day,
          );

          if (lastSessionDate == null) {
            streak = 1;
            lastSessionDate = sessionDate;
          } else {
            final daysDifference = sessionDate
                .difference(lastSessionDate)
                .inDays;
            if (daysDifference == 1) {
              streak++;
              lastSessionDate = sessionDate;
            } else if (daysDifference > 1) {
              break;
            }
          }
        }
      }

      return streak;
    } catch (e) {
      return 0;
    }
  }

  // Alias pour compatibilité
  Future<List<FocusSession>> getUserSessions(
    String userId, {
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return getUserFocusSessions(
      userId,
      limit: limit,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Compter les sessions utilisateur
  Future<int> getUserSessionsCount(String userId) async {
    try {
      final response = await _supabase.client
          .from(_table)
          .select('id')
          .eq('user_id', userId);

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  // Obtenir le streak actuel
  Future<int> getCurrentStreak(String userId) async {
    return await _calculateStreakManually(userId);
  }

  // Démarrer une session
  Future<FocusSession> startSession({
    required String userId,
    required int duration,
    String sessionType = 'focus',
    String? goal,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final sessionData = <String, dynamic>{
        'user_id': userId,
        'planned_duration': duration,
        'session_type': sessionType,
        'status': 'in_progress',
        'started_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (goal != null) {
        sessionData['goal'] = goal;
      }

      if (metadata != null) {
        sessionData['metadata'] = metadata;
      }

      final response = await _supabase.client
          .from(_table)
          .insert(sessionData)
          .select()
          .single();

      return FocusSession.fromJson(response);
    } catch (e) {
      throw Exception('Failed to start session: $e');
    }
  }

  // Terminer une session
  Future<FocusSession> endSession(
    String sessionId,
    String status, {
    int? actualDuration,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'completed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (actualDuration != null) {
        updateData['actual_duration'] = actualDuration;
      }

      final response = await _supabase.client
          .from(_table)
          .update(updateData)
          .eq('id', sessionId)
          .select()
          .single();

      return FocusSession.fromJson(response);
    } catch (e) {
      throw Exception('Failed to end session: $e');
    }
  }
}
