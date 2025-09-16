class UserChallenge {
  final String id;
  final String userId;
  final String challengeId;
  final String? teamId;
  final String? teamName;
  final String status;
  final Map<String, dynamic> progress;
  final int score;
  final double completionPercentage;
  final DateTime assignedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  final int xpEarned;
  final int leaguePointsEarned;
  final List<String>? badgesEarned;
  final String assignedBy;
  final int? difficultyCompleted;
  final DateTime createdAt;

  const UserChallenge({
    required this.id,
    required this.userId,
    required this.challengeId,
    this.teamId,
    this.teamName,
    this.status = 'pending',
    this.progress = const {},
    this.score = 0,
    this.completionPercentage = 0.0,
    required this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.expiresAt,
    this.xpEarned = 0,
    this.leaguePointsEarned = 0,
    this.badgesEarned,
    this.assignedBy = 'system',
    this.difficultyCompleted,
    required this.createdAt,
  });

  factory UserChallenge.fromJson(Map<String, dynamic> json) {
    return UserChallenge(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      challengeId: json['challenge_id'] as String,
      teamId: json['team_id'] as String?,
      teamName: json['team_name'] as String?,
      status: json['status'] as String? ?? 'pending',
      progress: json['progress'] as Map<String, dynamic>? ?? {},
      score: json['score'] as int? ?? 0,
      completionPercentage:
          (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      assignedAt: DateTime.parse(json['assigned_at']),
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      xpEarned: json['xp_earned'] as int? ?? 0,
      leaguePointsEarned: json['league_points_earned'] as int? ?? 0,
      badgesEarned: json['badges_earned'] != null
          ? List<String>.from(json['badges_earned'])
          : null,
      assignedBy: json['assigned_by'] as String? ?? 'system',
      difficultyCompleted: json['difficulty_completed'] as int?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'challenge_id': challengeId,
      'team_id': teamId,
      'team_name': teamName,
      'status': status,
      'progress': progress,
      'score': score,
      'completion_percentage': completionPercentage,
      'assigned_at': assignedAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'xp_earned': xpEarned,
      'league_points_earned': leaguePointsEarned,
      'badges_earned': badgesEarned,
      'assigned_by': assignedBy,
      'difficulty_completed': difficultyCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
