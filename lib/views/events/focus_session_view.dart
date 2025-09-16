import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/focus_session_controller.dart';
import '../widgets/widgets.dart';

class FocusSessionView extends ConsumerStatefulWidget {
  final int? duration;

  const FocusSessionView({super.key, this.duration});

  @override
  ConsumerState<FocusSessionView> createState() => _FocusSessionViewState();
}

class _FocusSessionViewState extends ConsumerState<FocusSessionView> {
  @override
  void initState() {
    super.initState();
    // Charger les données de focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(focusSessionControllerProvider.notifier).loadActiveSession();
      ref.read(focusSessionControllerProvider.notifier).loadRecentSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final focusState = ref.watch(focusSessionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions Focus'),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: _showHistory),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: _showStats,
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session active ou démarrer une nouvelle session
            if (focusState.currentSession != null)
              _buildActiveSession()
            else
              _buildStartSession(),

            const SizedBox(height: 32),

            // Sessions prédéfinies
            _buildPresetSessions(),

            const SizedBox(height: 32),

            // Sessions récentes
            _buildRecentSessions(),

            const SizedBox(height: 32),

            // Statistiques rapides
            _buildQuickStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSession() {
    final focusState = ref.watch(focusSessionControllerProvider);

    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session en cours',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Text(
                        focusState.currentSession!.sessionType ?? 'Focus',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (focusState.isPaused)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'EN PAUSE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 32),

            // Timer principal
            Text(
              _formatDuration(focusState.remaining),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),

            const SizedBox(height: 16),

            // Barre de progression
            LinearProgressIndicator(
              value: focusState.currentSession!.duration > 0
                  ? focusState.elapsed.inSeconds /
                        (focusState.currentSession!.duration * 60)
                  : 0.0,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.3),
              minHeight: 8,
            ),

            const SizedBox(height: 16),

            Text(
              '${focusState.elapsed.inMinutes} / ${focusState.currentSession!.duration} minutes',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 32),

            // Contrôles
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
    );
  }

  Widget _buildStartSession() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.timer_outlined,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),

            const SizedBox(height: 16),

            Text(
              'Prêt pour une session de focus ?',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Choisissez une durée et commencez à vous concentrer sans distractions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startQuickSession(25),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Démarrer 25 min (Pomodoro)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetSessions() {
    final presets = ref
        .read(focusSessionControllerProvider.notifier)
        .getPresetSessions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sessions prédéfinies',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 12),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: presets.length,
          itemBuilder: (context, index) {
            final preset = presets[index];
            return Card(
              child: InkWell(
                onTap: () {
                  if (preset['type'] == 'custom') {
                    _showCustomDurationDialog();
                  } else {
                    _startQuickSession(preset['duration'] as int);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        preset['name'] as String,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preset['duration'] == 0
                            ? '?'
                            : '${preset['duration']} min',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentSessions() {
    final focusState = ref.watch(focusSessionControllerProvider);
    final recentSessions = focusState.recentSessions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sessions récentes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            TextButton(onPressed: _showHistory, child: const Text('Voir tout')),
          ],
        ),

        const SizedBox(height: 12),

        if (recentSessions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Aucune session récente',
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
          Column(
            children: recentSessions
                .map(
                  (session) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.withOpacity(0.1),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                      title: Text('${session.duration} minutes'),
                      subtitle: Text(
                        _formatSessionDate(
                          session.startedAt ?? session.createdAt,
                        ),
                      ),
                      trailing: Text(
                        '+${session.xpGained ?? 0} XP',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(focusSessionControllerProvider.notifier).getFocusStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vos statistiques',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    title: 'Aujourd\'hui',
                    value: '${stats['today_minutes'] ?? 0}',
                    subtitle: 'minutes',
                    icon: Icons.today,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    title: 'Streak',
                    value: '${stats['current_streak'] ?? 0}',
                    subtitle: 'jours',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatSessionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(date.year, date.month, date.day);

    if (sessionDate == today) {
      return 'Aujourd\'hui ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (sessionDate == today.subtract(const Duration(days: 1))) {
      return 'Hier ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  void _startQuickSession(int minutes) {
    ref
        .read(focusSessionControllerProvider.notifier)
        .startSession(duration: minutes, type: 'pomodoro');
  }

  void _showCustomDurationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Durée personnalisée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choisissez la durée de votre session (en minutes)'),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Minutes',
              ),
              onSubmitted: (value) {
                final minutes = int.tryParse(value);
                if (minutes != null && minutes > 0) {
                  Navigator.of(context).pop();
                  _startQuickSession(minutes);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showHistory() {
    // Navigation vers l'historique détaillé
  }

  void _showStats() {
    // Navigation vers les statistiques détaillées
  }
}
