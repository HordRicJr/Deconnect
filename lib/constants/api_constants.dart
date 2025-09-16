// Constantes API
class ApiConstants {
  // URLs de base
  static const String baseUrl = 'https://your-project.supabase.co';
  static const String apiPrefix = 'rest/v1';
  static const String authPrefix = 'auth/v1';

  // Endpoints principaux
  static const String profilesEndpoint = 'profiles';
  static const String organizationsEndpoint = 'organizations';
  static const String challengesEndpoint = 'challenges';
  static const String focusSessionsEndpoint = 'focus_sessions';
  static const String irlEventsEndpoint = 'irl_events';

  // Timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);

  // Limites
  static const int maxRetries = 3;
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
