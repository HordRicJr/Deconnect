import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/dashboard_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/challenges_controller.dart';
import '../../controllers/focus_session_controller.dart';
import '../../models/focus_session.dart';
import '../widgets/widgets.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  @override
  void initState() {
    super.initState();
    // Charger les données du dashboard au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardControllerProvider.notifier).loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardControllerProvider);
    final profileState = ref.watch(profileControllerProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar personnalisée
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Salut ${profileState.profile?.firstName ?? ""}!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _getGreetingMessage(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // Navigation vers les notifications
                },
              ),
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () {
                  // Navigation vers le profil
                },
              ),
            ],
          ),

          // Contenu principal
          if (dashboardState.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (dashboardState.error != null)
            SliverFillRemaining(
              child: CustomErrorWidget(
                error: dashboardState.error!,
                onRetry: () => ref
                    .read(dashboardControllerProvider.notifier)
                    .loadDashboardData(),
              ),
            )
          else
            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),

                // Statistiques principales
                _buildStatsSection(),

                const SizedBox(height: 24),

                // Session de focus active
                _buildActiveFocusSession(),

                const SizedBox(height: 24),

                // Défis actifs
                _buildActiveChallenges(),

                const SizedBox(height: 24),

                // Événements à venir
                _buildUpcomingEvents(),

                const SizedBox(height: 24),

                // Activité récente
                _buildRecentActivity(),

                const SizedBox(height: 100), // Espace pour la navigation
              ]),
            ),
        ],
      ),

      // Bouton d'action flottant pour démarrer une session de focus
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startQuickFocusSession,
        icon: const Icon(Icons.timer_outlined),
        label: const Text('Focus'),
      ),
    );
  }

  Widget _buildStatsSection() {
    final dashboardState = ref.watch(dashboardControllerProvider);
    final stats = dashboardState.stats;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Votre progression aujourd\'hui',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Minutes de focus',
                  value: '${stats?['focus_minutes'] ?? 0}',
                  subtitle: 'min aujourd\'hui',
                  icon: Icons.timer_outlined,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatsCard(
                  title: 'Défis complétés',
                  value: '${stats?['completed_challenges'] ?? 0}',
                  subtitle: 'cette semaine',
                  icon: Icons.emoji_events_outlined,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Streak actuelle',
                  value: '${stats?['current_streak'] ?? 0}',
                  subtitle: 'jours consécutifs',
                  icon: Icons.local_fire_department_outlined,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatsCard(
                  title: 'XP total',
                  value: '${stats?['total_xp'] ?? 0}',
                  subtitle: 'points d\'expérience',
                  icon: Icons.star_outlined,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFocusSession() {
    final focusState = ref.watch(focusSessionControllerProvider);

    if (focusState.currentSession == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Session de focus',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Aucune session en cours. Commencez une session pour améliorer votre concentration !',
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _startQuickFocusSession,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Démarrer 25 min'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.timer, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Session en cours',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const Spacer(),
                  if (focusState.isPaused)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'PAUSE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Timer display
              Center(
                child: Text(
                  _formatDuration(focusState.remaining),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Progress bar
              LinearProgressIndicator(
                value: focusState.currentSession!.duration > 0
                    ? focusState.elapsed.inSeconds /
                          (focusState.currentSession!.duration * 60)
                    : 0.0,
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.3),
              ),

              const SizedBox(height: 16),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ref
                          .read(focusSessionControllerProvider.notifier)
                          .stopSession();
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Arrêter'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (focusState.isPaused) {
                        ref
                            .read(focusSessionControllerProvider.notifier)
                            .resumeSession();
                      } else {
                        ref
                            .read(focusSessionControllerProvider.notifier)
                            .pauseSession();
                      }
                    },
                    icon: Icon(
                      focusState.isPaused ? Icons.play_arrow : Icons.pause,
                    ),
                    label: Text(focusState.isPaused ? 'Reprendre' : 'Pause'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveChallenges() {
    final challengesState = ref.watch(challengesControllerProvider);
    final activeChallenges = challengesState.userChallenges
        .where((c) => c.status == 'active')
        .take(3)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Défis en cours',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () {
                  // Navigation vers les défis
                },
                child: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (activeChallenges.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 48,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    const Text('Aucun défi actif'),
                    const SizedBox(height: 4),
                    const Text(
                      'Rejoignez un défi pour améliorer vos habitudes !',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        // Navigation vers les défis
                      },
                      child: const Text('Découvrir les défis'),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: activeChallenges
                  .map(
                    (challenge) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ChallengeCard(challenge: challenge),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    final dashboardState = ref.watch(dashboardControllerProvider);
    final upcomingEvents = dashboardState.upcomingEvents.take(2).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Événements à venir',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () {
                  // Navigation vers les événements
                },
                child: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (upcomingEvents.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 48,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    const Text('Aucun événement prévu'),
                    const SizedBox(height: 4),
                    const Text(
                      'Découvrez des événements près de chez vous !',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        // Navigation vers les événements
                      },
                      child: const Text('Explorer les événements'),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: upcomingEvents
                  .map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: EventCard(event: event),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final dashboardState = ref.watch(dashboardControllerProvider);
    final activities = dashboardState.recentActivities.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activité récente',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (activities.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Aucune activité récente',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: activities
                    .asMap()
                    .entries
                    .map(
                      (entry) => ActivityTile(
                        activity: _focusSessionToActivity(entry.value),
                        showDivider: entry.key < activities.length - 1,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, dynamic> _focusSessionToActivity(FocusSession session) {
    return {
      'title': 'Session de focus',
      'description':
          '${session.plannedDuration} minutes - ${session.sessionType}',
      'time': session.startedAt ?? session.createdAt,
      'type': 'focus',
    };
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Bonne matinée !';
    } else if (hour < 18) {
      return 'Bon après-midi !';
    } else {
      return 'Bonne soirée !';
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _startQuickFocusSession() {
    ref
        .read(focusSessionControllerProvider.notifier)
        .startSession(
          duration: 25, // 25 minutes par défaut
          type: 'pomodoro',
          goal: 'Session rapide depuis le dashboard',
        );
  }
}
