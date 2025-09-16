import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/profile_controller.dart';
import '../../controllers/challenges_controller.dart';
import '../../controllers/focus_session_controller.dart';
import '../widgets/widgets.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Charger les données du profil
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileControllerProvider.notifier).loadProfile();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildProfileHeader(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    // Navigation vers les paramètres
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditProfileDialog();
                        break;
                      case 'share':
                        _shareProfile();
                        break;
                      case 'logout':
                        _showLogoutDialog();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 8),
                          Text('Modifier le profil'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined),
                          SizedBox(width: 8),
                          Text('Partager le profil'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_outlined, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Déconnexion',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Statistiques'),
                  Tab(text: 'Activités'),
                  Tab(text: 'Badges'),
                ],
              ),
            ),
          ];
        },
        body: profileState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : profileState.error != null
            ? CustomErrorWidget(
                error: profileState.error!,
                onRetry: () =>
                    ref.read(profileControllerProvider.notifier).loadProfile(),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildStatsTab(),
                  _buildActivitiesTab(),
                  _buildBadgesTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(height: 40), // Space for status bar
          // Photo de profil
          CircleAvatar(
            radius: 40,
            backgroundImage: profile?.avatarUrl != null
                ? NetworkImage(profile!.avatarUrl!)
                : null,
            child: profile?.avatarUrl == null
                ? Text(
                    profile?.firstName?.isNotEmpty == true
                        ? profile!.firstName![0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),

          const SizedBox(height: 12),

          // Nom et informations
          Text(
            '${profile?.firstName ?? ""} ${profile?.lastName ?? ""}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          if (profile?.bio?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              profile!.bio!,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 12),

          // Statistiques rapides
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickStat('Niveau', '${profile?.level ?? 0}'),
              _buildQuickStat('XP', '${profile?.totalXp ?? 0}'),
              _buildQuickStat('Streak', '${profileState.currentStreak}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildStatsTab() {
    final profileState = ref.watch(profileControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progression du niveau
          _buildLevelProgress(),

          const SizedBox(height: 24),

          // Statistiques de focus
          _buildFocusStats(),

          const SizedBox(height: 24),

          // Statistiques des défis
          _buildChallengeStats(),

          const SizedBox(height: 24),

          // Statistiques des événements
          _buildEventStats(),
        ],
      ),
    );
  }

  Widget _buildLevelProgress() {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;

    final currentLevel = profile?.level ?? 1;
    final currentXP = profile?.totalXp ?? 0;
    final xpForCurrentLevel = _getXPRequiredForLevel(currentLevel);
    final xpForNextLevel = _getXPRequiredForLevel(currentLevel + 1);
    final progressInLevel =
        ((currentXP - xpForCurrentLevel) / (xpForNextLevel - xpForCurrentLevel))
            .clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Progression',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Niveau $currentLevel'),
                Text('Niveau ${currentLevel + 1}'),
              ],
            ),

            const SizedBox(height: 8),

            LinearProgressIndicator(
              value: progressInLevel,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            ),

            const SizedBox(height: 8),

            Text(
              '${currentXP - xpForCurrentLevel} / ${xpForNextLevel - xpForCurrentLevel} XP',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(focusSessionControllerProvider.notifier).getFocusStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};

        return Card(
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
                      'Sessions de focus',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Aujourd\'hui',
                        '${stats['today_minutes'] ?? 0} min',
                        '${stats['today_sessions'] ?? 0} sessions',
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Cette semaine',
                        '${stats['week_minutes'] ?? 0} min',
                        '${stats['week_sessions'] ?? 0} sessions',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Streak actuel',
                        '${stats['current_streak'] ?? 0}',
                        'jours consécutifs',
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Total',
                        '${stats['total_sessions'] ?? 0}',
                        'sessions complétées',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChallengeStats() {
    final challengesState = ref.watch(challengesControllerProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Défis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Actifs',
                    '${challengesState.userChallenges.where((c) => c.status == 'active').length}',
                    'en cours',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Complétés',
                    '${challengesState.userChallenges.where((c) => c.status == 'completed').length}',
                    'terminés',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Événements',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Organisés',
                    '0', // À implémenter
                    'événements créés',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Participations',
                    '0', // À implémenter
                    'événements rejoints',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesTab() {
    final profileState = ref.watch(profileControllerProvider);
    final activities = profileState.recentActivities;

    return activities.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Aucune activité récente'),
                Text(
                  'Commencez à utiliser l\'app pour voir vos activités ici !',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return ActivityTile(
                activity: activity,
                showDivider: index < activities.length - 1,
              );
            },
          );
  }

  Widget _buildBadgesTab() {
    final profileState = ref.watch(profileControllerProvider);
    final badges = profileState.badges;

    return badges.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.military_tech_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text('Aucun badge gagné'),
                Text(
                  'Complétez des défis et atteignez des objectifs pour débloquer des badges !',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              return BadgeCard(badge: badge);
            },
          );
  }

  void _showEditProfileDialog() {
    // À implémenter - dialogue d'édition du profil
  }

  void _shareProfile() {
    // À implémenter - partage du profil
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(profileControllerProvider.notifier).signOut(context);
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  int _getXPRequiredForLevel(int level) {
    // Formule simple : niveau^2 * 100
    return level * level * 100;
  }
}
