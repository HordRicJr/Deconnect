class Profile {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? phone;
  final DateTime? dateOfBirth;
  final String timezone;
  final String? organizationId;
  final String organizationRole;
  final DateTime? joinedOrganizationAt;
  final String role;
  final String coachTone;
  final String language;
  final String theme;
  final int totalXp;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final double focusScore;
  final String league;
  final int leaguePoints;
  final int? weeklyRank;
  final String avatarType;
  final int avatarLevel;
  final double avatarHealth;
  final Map<String, dynamic> avatarCustomization;
  final List<dynamic> avatarAccessories;
  final int totalFocusTime;
  final int appsBlockedCount;
  final int challengesCompleted;
  final int socialPoints;
  final int wellnessPoints;
  final String subscriptionTier;
  final DateTime? subscriptionExpiresAt;
  final bool aiCoachingEnabled;
  final Map<String, dynamic> aiPersonalityTraits;
  final bool predictionOptIn;
  final bool onboardingCompleted;
  final Map<String, dynamic> privacySettings;
  final Map<String, dynamic> notificationSettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.phone,
    this.dateOfBirth,
    this.timezone = 'UTC',
    this.organizationId,
    this.organizationRole = 'member',
    this.joinedOrganizationAt,
    this.role = 'user',
    this.coachTone = 'friendly',
    this.language = 'fr',
    this.theme = 'light',
    this.totalXp = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.focusScore = 0.0,
    this.league = 'bronze',
    this.leaguePoints = 0,
    this.weeklyRank,
    this.avatarType = 'tree',
    this.avatarLevel = 1,
    this.avatarHealth = 1.0,
    this.avatarCustomization = const {},
    this.avatarAccessories = const [],
    this.totalFocusTime = 0,
    this.appsBlockedCount = 0,
    this.challengesCompleted = 0,
    this.socialPoints = 0,
    this.wellnessPoints = 0,
    this.subscriptionTier = 'free',
    this.subscriptionExpiresAt,
    this.aiCoachingEnabled = true,
    this.aiPersonalityTraits = const {},
    this.predictionOptIn = true,
    this.onboardingCompleted = false,
    this.privacySettings = const {},
    this.notificationSettings = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      timezone: json['timezone'] as String? ?? 'UTC',
      organizationId: json['organization_id'] as String?,
      organizationRole: json['organization_role'] as String? ?? 'member',
      joinedOrganizationAt: json['joined_organization_at'] != null
          ? DateTime.parse(json['joined_organization_at'])
          : null,
      role: json['role'] as String? ?? 'user',
      coachTone: json['coach_tone'] as String? ?? 'friendly',
      language: json['language'] as String? ?? 'fr',
      theme: json['theme'] as String? ?? 'light',
      totalXp: json['total_xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      focusScore: (json['focus_score'] as num?)?.toDouble() ?? 0.0,
      league: json['league'] as String? ?? 'bronze',
      leaguePoints: json['league_points'] as int? ?? 0,
      weeklyRank: json['weekly_rank'] as int?,
      avatarType: json['avatar_type'] as String? ?? 'tree',
      avatarLevel: json['avatar_level'] as int? ?? 1,
      avatarHealth: (json['avatar_health'] as num?)?.toDouble() ?? 1.0,
      avatarCustomization:
          json['avatar_customization'] as Map<String, dynamic>? ?? {},
      avatarAccessories: json['avatar_accessories'] as List<dynamic>? ?? [],
      totalFocusTime: json['total_focus_time'] as int? ?? 0,
      appsBlockedCount: json['apps_blocked_count'] as int? ?? 0,
      challengesCompleted: json['challenges_completed'] as int? ?? 0,
      socialPoints: json['social_points'] as int? ?? 0,
      wellnessPoints: json['wellness_points'] as int? ?? 0,
      subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      subscriptionExpiresAt: json['subscription_expires_at'] != null
          ? DateTime.parse(json['subscription_expires_at'])
          : null,
      aiCoachingEnabled: json['ai_coaching_enabled'] as bool? ?? true,
      aiPersonalityTraits:
          json['ai_personality_traits'] as Map<String, dynamic>? ?? {},
      predictionOptIn: json['prediction_opt_in'] as bool? ?? true,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      privacySettings: json['privacy_settings'] as Map<String, dynamic>? ?? {},
      notificationSettings:
          json['notification_settings'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'phone': phone,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'timezone': timezone,
      'organization_id': organizationId,
      'organization_role': organizationRole,
      'joined_organization_at': joinedOrganizationAt?.toIso8601String(),
      'role': role,
      'coach_tone': coachTone,
      'language': language,
      'theme': theme,
      'total_xp': totalXp,
      'level': level,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'focus_score': focusScore,
      'league': league,
      'league_points': leaguePoints,
      'weekly_rank': weeklyRank,
      'avatar_type': avatarType,
      'avatar_level': avatarLevel,
      'avatar_health': avatarHealth,
      'avatar_customization': avatarCustomization,
      'avatar_accessories': avatarAccessories,
      'total_focus_time': totalFocusTime,
      'apps_blocked_count': appsBlockedCount,
      'challenges_completed': challengesCompleted,
      'social_points': socialPoints,
      'wellness_points': wellnessPoints,
      'subscription_tier': subscriptionTier,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'ai_coaching_enabled': aiCoachingEnabled,
      'ai_personality_traits': aiPersonalityTraits,
      'prediction_opt_in': predictionOptIn,
      'onboarding_completed': onboardingCompleted,
      'privacy_settings': privacySettings,
      'notification_settings': notificationSettings,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? username,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? phone,
    DateTime? dateOfBirth,
    String? timezone,
    String? organizationId,
    String? organizationRole,
    DateTime? joinedOrganizationAt,
    String? role,
    String? coachTone,
    String? language,
    String? theme,
    int? totalXp,
    int? level,
    int? currentStreak,
    int? longestStreak,
    double? focusScore,
    String? league,
    int? leaguePoints,
    int? weeklyRank,
    String? avatarType,
    int? avatarLevel,
    double? avatarHealth,
    Map<String, dynamic>? avatarCustomization,
    List<dynamic>? avatarAccessories,
    int? totalFocusTime,
    int? appsBlockedCount,
    int? challengesCompleted,
    int? socialPoints,
    int? wellnessPoints,
    String? subscriptionTier,
    DateTime? subscriptionExpiresAt,
    bool? aiCoachingEnabled,
    Map<String, dynamic>? aiPersonalityTraits,
    bool? predictionOptIn,
    bool? onboardingCompleted,
    Map<String, dynamic>? privacySettings,
    Map<String, dynamic>? notificationSettings,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      timezone: timezone ?? this.timezone,
      organizationId: organizationId ?? this.organizationId,
      organizationRole: organizationRole ?? this.organizationRole,
      joinedOrganizationAt: joinedOrganizationAt ?? this.joinedOrganizationAt,
      role: role ?? this.role,
      coachTone: coachTone ?? this.coachTone,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      focusScore: focusScore ?? this.focusScore,
      league: league ?? this.league,
      leaguePoints: leaguePoints ?? this.leaguePoints,
      weeklyRank: weeklyRank ?? this.weeklyRank,
      avatarType: avatarType ?? this.avatarType,
      avatarLevel: avatarLevel ?? this.avatarLevel,
      avatarHealth: avatarHealth ?? this.avatarHealth,
      avatarCustomization: avatarCustomization ?? this.avatarCustomization,
      avatarAccessories: avatarAccessories ?? this.avatarAccessories,
      totalFocusTime: totalFocusTime ?? this.totalFocusTime,
      appsBlockedCount: appsBlockedCount ?? this.appsBlockedCount,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
      socialPoints: socialPoints ?? this.socialPoints,
      wellnessPoints: wellnessPoints ?? this.wellnessPoints,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiresAt:
          subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      aiCoachingEnabled: aiCoachingEnabled ?? this.aiCoachingEnabled,
      aiPersonalityTraits: aiPersonalityTraits ?? this.aiPersonalityTraits,
      predictionOptIn: predictionOptIn ?? this.predictionOptIn,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      privacySettings: privacySettings ?? this.privacySettings,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Getters convenants
  String? get firstName {
    if (fullName == null) return null;
    final parts = fullName!.split(' ');
    return parts.isNotEmpty ? parts.first : null;
  }

  String? get lastName {
    if (fullName == null) return null;
    final parts = fullName!.split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : null;
  }

  String? get bio {
    // Retourne une bio basique basée sur les données du profil
    return 'Niveau $level • ${currentStreak} jours de suite';
  }

  int get experience => totalXp;

  bool get isPublic {
    return privacySettings['isPublic'] as bool? ?? true;
  }

  // Getters pour settings_view.dart
  String? get displayName => fullName ?? username;

  bool get focusNotifications => notificationSettings['focus'] as bool? ?? true;

  bool get eventNotifications =>
      notificationSettings['events'] as bool? ?? true;

  int get defaultFocusDuration =>
      privacySettings['defaultFocusDuration'] as int? ?? 25;

  bool get soundEnabled => notificationSettings['sound'] as bool? ?? true;

  bool get showStats => privacySettings['showStats'] as bool? ?? true;
}
