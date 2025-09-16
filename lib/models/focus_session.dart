class FocusSession {
  final String id;
  final String userId;
  final int plannedDuration;
  final int? actualDuration;
  final String sessionType;
  final String? challengeId;
  final String status;
  final int interruptionsCount;
  final int appsBlockedDuring;
  final double qualityScore;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int pausedDuration;
  final int xpEarned;
  final int leaguePointsEarned;
  final Map<String, dynamic> contextData;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FocusSession({
    required this.id,
    required this.userId,
    required this.plannedDuration,
    this.actualDuration,
    this.sessionType = 'focus',
    this.challengeId,
    this.status = 'planned',
    this.interruptionsCount = 0,
    this.appsBlockedDuring = 0,
    this.qualityScore = 1.0,
    this.startedAt,
    this.completedAt,
    this.pausedDuration = 0,
    this.xpEarned = 0,
    this.leaguePointsEarned = 0,
    this.contextData = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      plannedDuration: json['planned_duration'] as int,
      actualDuration: json['actual_duration'] as int?,
      sessionType: json['session_type'] as String? ?? 'focus',
      challengeId: json['challenge_id'] as String?,
      status: json['status'] as String? ?? 'planned',
      interruptionsCount: json['interruptions_count'] as int? ?? 0,
      appsBlockedDuring: json['apps_blocked_during'] as int? ?? 0,
      qualityScore: (json['quality_score'] as num?)?.toDouble() ?? 1.0,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      pausedDuration: json['paused_duration'] as int? ?? 0,
      xpEarned: json['xp_earned'] as int? ?? 0,
      leaguePointsEarned: json['league_points_earned'] as int? ?? 0,
      contextData: json['context_data'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'planned_duration': plannedDuration,
      'actual_duration': actualDuration,
      'session_type': sessionType,
      'challenge_id': challengeId,
      'status': status,
      'interruptions_count': interruptionsCount,
      'apps_blocked_during': appsBlockedDuring,
      'quality_score': qualityScore,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'paused_duration': pausedDuration,
      'xp_earned': xpEarned,
      'league_points_earned': leaguePointsEarned,
      'context_data': contextData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Getters convenants
  int get duration => actualDuration ?? plannedDuration;

  DateTime? get startTime => startedAt;

  int get xpGained => xpEarned;
}
