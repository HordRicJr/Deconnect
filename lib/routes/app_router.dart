import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth/auth_service.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/auth/forgot_password_view.dart';
import '../views/auth/onboarding_view.dart';
import '../views/auth/splash_view.dart';
import '../views/main/main_navigation_view.dart';
import '../views/main/dashboard_view.dart';
import '../views/main/challenges_view.dart';
import '../views/main/profile_view.dart';
import '../views/main/focus_view.dart';
import '../views/events/events_view.dart';
import '../views/events/focus_session_view.dart';
import '../views/main/settings_view.dart';
import '../views/widgets/common/app_shell.dart';
import '../views/challenges/challenge_detail_view.dart';
import '../views/placeholders/placeholder_functions.dart' as placeholders;
import '../views/events/event_detail_view.dart';
import '../views/organizations/organization_detail_view.dart';
import '../views/placeholders/add_event_views.dart';

// Clés de navigation globales
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

// Provider pour le routeur
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: _handleRedirect,
    routes: [
      // Routes d'authentification (sans shell)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordView(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingView(),
      ),

      // Shell avec navigation bottom bar pour les routes principales
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // Accueil / Dashboard
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const DashboardView(),
            routes: [
              GoRoute(
                path: 'dashboard',
                name: 'dashboard',
                builder: (context, state) => const DashboardView(),
              ),
            ],
          ),

          // Défis
          GoRoute(
            path: '/challenges',
            name: 'challenges',
            builder: (context, state) => const ChallengesView(),
            routes: [
              GoRoute(
                path: '/:id',
                name: 'challenge-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ChallengeDetailView(challengeId: id);
                },
              ),
            ],
          ),

          // Focus / Sessions
          GoRoute(
            path: '/focus',
            name: 'focus',
            builder: (context, state) => const FocusView(),
            routes: [
              GoRoute(
                path: '/session',
                name: 'focus-session',
                builder: (context, state) {
                  final duration =
                      int.tryParse(
                        state.uri.queryParameters['duration'] ?? '25',
                      ) ??
                      25;
                  return FocusSessionView(duration: duration);
                },
              ),
            ],
          ),

          // Événements IRL
          GoRoute(
            path: '/events',
            name: 'events',
            builder: (context, state) => const EventsView(),
            routes: [
              GoRoute(
                path: '/create',
                name: 'create-event',
                builder: (context, state) => const CreateEventView(),
              ),
              GoRoute(
                path: '/:id',
                name: 'event-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return EventDetailView(eventId: id);
                },
              ),
            ],
          ),

          // Organisations
          GoRoute(
            path: '/organizations',
            name: 'organizations',
            builder: (context, state) => const OrganizationsView(),
            routes: [
              GoRoute(
                path: '/:id',
                name: 'organization-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return OrganizationDetailView(organizationId: id);
                },
              ),
            ],
          ),

          // Profil
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileView(),
            routes: [
              GoRoute(
                path: '/edit',
                name: 'edit-profile',
                builder: (context, state) => const EditProfileView(),
              ),
            ],
          ),

          // Recherche
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) => placeholders.SearchView(),
          ),

          // Paramètres
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsView(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => ErrorView(error: state.error.toString()),
  );
});

// Fonction de redirection pour gérer l'authentification
String? _handleRedirect(BuildContext context, GoRouterState state) {
  final authService = AuthService.instance;
  final isAuthenticated = authService.isAuthenticated;
  final isTokenValid = authService.isTokenValid;

  // Routes publiques (accessible sans authentification)
  final publicRoutes = ['/login', '/register', '/forgot-password'];
  final isPublicRoute = publicRoutes.contains(state.matchedLocation);

  // Si l'utilisateur n'est pas authentifié ou que le token n'est pas valide
  if (!isAuthenticated || !isTokenValid) {
    // S'il n'est pas sur une route publique, rediriger vers login
    if (!isPublicRoute) {
      return '/login';
    }
  } else {
    // Si l'utilisateur est authentifié mais sur une route publique
    if (isPublicRoute) {
      return '/'; // Rediriger vers l'accueil
    }

    // Vérifier si l'utilisateur a complété l'onboarding
    // Cette logique peut être ajoutée selon vos besoins
    // if (!userHasCompletedOnboarding && state.matchedLocation != '/onboarding') {
    //   return '/onboarding';
    // }
  }

  return null; // Pas de redirection nécessaire
}

// Shell avec bottom navigation
class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Défis',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Focus'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Événements'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final GoRouterState state = GoRouterState.of(context);
    final location = state.matchedLocation;

    if (location.startsWith('/challenges')) return 1;
    if (location.startsWith('/focus')) return 2;
    if (location.startsWith('/events')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0; // Home par défaut
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/challenges');
        break;
      case 2:
        context.go('/focus');
        break;
      case 3:
        context.go('/events');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}

// Widget d'erreur
class ErrorView extends StatelessWidget {
  final String error;

  const ErrorView({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erreur')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Une erreur s\'est produite',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }
}

// Extensions utiles pour la navigation
extension GoRouterExtension on BuildContext {
  // Navigation sécurisée avec vérification d'authentification
  void goSecure(String location) {
    final authService = AuthService.instance;
    if (!authService.isAuthenticated || !authService.isTokenValid) {
      go('/login');
    } else {
      go(location);
    }
  }

  // Navigation avec paramètres de requête
  void goWithQuery(String location, Map<String, String> queryParams) {
    final uri = Uri.parse(location).replace(queryParameters: queryParams);
    go(uri.toString());
  }

  // Pousser avec paramètres de requête
  void pushWithQuery(String location, Map<String, String> queryParams) {
    final uri = Uri.parse(location).replace(queryParameters: queryParams);
    push(uri.toString());
  }
}
