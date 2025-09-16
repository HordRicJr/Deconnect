class Challenge {
  final String id;
  final String? organizationId;
  final String typeId;
  final String title;
  final String? description;
  final String? instructions;
  final int difficulty;
  final int? estimatedDuration;
  final int xpReward;
  final int leaguePointsReward;
  final Map<String, dynamic> content;
  final int unlockLevel;
  final List<String>? requiredBadges;
  final String? requiredLeague;
  final bool isRecurring;
  final String? recurrencePattern;
  final bool isTeamChallenge;
  final int minTeamSize;
  final int maxTeamSize;
  final bool isActive;
  final bool isPremium;
  final bool isFeatured;
  final DateTime createdAt;

  const Challenge({
    required this.id,
    this.organizationId,
    required this.typeId,
    required this.title,
    this.description,
    this.instructions,
    this.difficulty = 1,
    this.estimatedDuration,
    this.xpReward = 0,
    this.leaguePointsReward = 0,
    this.content = const {},
    this.unlockLevel = 1,
    this.requiredBadges,
    this.requiredLeague,
    this.isRecurring = false,
    this.recurrencePattern,
    this.isTeamChallenge = false,
    this.minTeamSize = 1,
    this.maxTeamSize = 10,
    this.isActive = true,
    this.isPremium = false,
    this.isFeatured = false,
    required this.createdAt,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String?,
      typeId: json['type_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      instructions: json['instructions'] as String?,
      difficulty: json['difficulty'] as int? ?? 1,
      estimatedDuration: json['estimated_duration'] as int?,
      xpReward: json['xp_reward'] as int? ?? 0,
      leaguePointsReward: json['league_points_reward'] as int? ?? 0,
      content: json['content'] as Map<String, dynamic>? ?? {},
      unlockLevel: json['unlock_level'] as int? ?? 1,
      requiredBadges: json['required_badges'] != null
          ? List<String>.from(json['required_badges'])
          : null,
      requiredLeague: json['required_league'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrencePattern: json['recurrence_pattern'] as String?,
      isTeamChallenge: json['is_team_challenge'] as bool? ?? false,
      minTeamSize: json['min_team_size'] as int? ?? 1,
      maxTeamSize: json['max_team_size'] as int? ?? 10,
      isActive: json['is_active'] as bool? ?? true,
      isPremium: json['is_premium'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'type_id': typeId,
      'title': title,
      'description': description,
      'instructions': instructions,
      'difficulty': difficulty,
      'estimated_duration': estimatedDuration,
      'xp_reward': xpReward,
      'league_points_reward': leaguePointsReward,
      'content': content,
      'unlock_level': unlockLevel,
      'required_badges': requiredBadges,
      'required_league': requiredLeague,
      'is_recurring': isRecurring,
      'recurrence_pattern': recurrencePattern,
      'is_team_challenge': isTeamChallenge,
      'min_team_size': minTeamSize,
      'max_team_size': maxTeamSize,
      'is_active': isActive,
      'is_premium': isPremium,
      'is_featured': isFeatured,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
