// Constantes des routes
class RouteConstants {
  // Routes d'authentification
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String onboarding = '/onboarding';

  // Routes principales
  static const String home = '/';
  static const String dashboard = '/dashboard';

  // Profil
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';

  // Défis
  static const String challenges = '/challenges';
  static const String challengeDetail = '/challenges/:id';

  // Sessions de focus
  static const String focus = '/focus';
  static const String focusSession = '/focus/session';

  // Événements
  static const String events = '/events';
  static const String eventDetail = '/events/:id';
  static const String createEvent = '/events/create';

  // Organisations
  static const String organizations = '/organizations';
  static const String organizationDetail = '/organizations/:id';

  // Utilitaires
  static const String search = '/search';
  static const String settings = '/settings';

  // Helpers pour construire les routes avec paramètres
  static String buildChallengeDetail(String id) => '/challenges/$id';
  static String buildEventDetail(String id) => '/events/$id';
  static String buildOrganizationDetail(String id) => '/organizations/$id';

  // Routes avec query parameters
  static String buildSearchWithQuery(String query) => '/search?q=$query';
  static String buildFocusSessionWithDuration(int duration) =>
      '/focus/session?duration=$duration';
}
