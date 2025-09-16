// Constantes de l'application
class AppConstants {
  // Informations de l'app
  static const String appName = 'Deconnect';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';

  // URLs
  static const String websiteUrl = 'https://deconnect.app';
  static const String supportEmail = 'support@deconnect.app';
  static const String privacyPolicyUrl = 'https://deconnect.app/privacy';
  static const String termsOfServiceUrl = 'https://deconnect.app/terms';

  // Deep links
  static const String deepLinkScheme = 'com.deconnect';
  static const String authCallbackUrl = 'com.deconnect://auth-callback';
  static const String resetPasswordUrl = 'com.deconnect://reset-password';

  // Configuration par défaut
  static const int defaultFocusSessionDuration = 25; // minutes
  static const int shortBreakDuration = 5; // minutes
  static const int longBreakDuration = 15; // minutes
  static const int pomodoroSessions = 4;

  // Niveaux et XP
  static const int baseXpPerLevel = 100;
  static const double xpMultiplier = 1.2;
  static const int maxLevel = 100;

  // Leagues
  static const List<String> leagues = [
    'Bronze',
    'Silver',
    'Gold',
    'Platinum',
    'Diamond',
    'Master',
  ];

  // Points par action
  static const int xpFocusSession = 10;
  static const int xpChallengeCompleted = 50;
  static const int xpEventAttended = 25;
  static const int xpDailyGoal = 20;
  static const int xpStreakBonus = 5;

  // Limites
  static const int maxUsernameLength = 30;
  static const int minPasswordLength = 8;
  static const int maxBioLength = 500;
  static const int maxChallengeDescriptionLength = 1000;
  static const int maxEventDescriptionLength = 2000;

  // Durées
  static const Duration sessionTimeout = Duration(hours: 24);
  static const Duration refreshTokenLifetime = Duration(days: 30);
  static const Duration challengeDuration = Duration(days: 30);

  // Notifications
  static const String notificationChannelId = 'deconnect_main';
  static const String notificationChannelName = 'Deconnect Notifications';
  static const String focusNotificationChannelId = 'focus_sessions';
  static const String focusNotificationChannelName = 'Focus Sessions';

  // Thèmes
  static const String lightTheme = 'light';
  static const String darkTheme = 'dark';
  static const String systemTheme = 'system';

  // Locales supportées
  static const List<String> supportedLocales = ['fr', 'en'];
  static const String defaultLocale = 'en';
}
