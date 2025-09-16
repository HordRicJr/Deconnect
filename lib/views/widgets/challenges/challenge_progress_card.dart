import 'package:flutter/material.dart';

class ChallengeProgressCard extends StatelessWidget {
  final dynamic challenge;
  final VoidCallback? onTap;

  const ChallengeProgressCard({super.key, required this.challenge, this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress();
    final daysLeft = _calculateDaysLeft();

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      challenge.title ?? 'Défi sans titre',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'En cours',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Text(
                    'Progression: ${(progress * 100).round()}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$daysLeft jours restants',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              LinearProgressIndicator(
                value: progress,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress < 0.3
                      ? Colors.red
                      : progress < 0.7
                      ? Colors.orange
                      : Colors.green,
                ),
              ),

              const SizedBox(height: 12),

              if (challenge.target != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.track_changes,
                      size: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Objectif: ${challenge.currentValue ?? 0} / ${challenge.target}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _calculateProgress() {
    if (challenge.startDate == null || challenge.duration == null) return 0.0;

    final startDate = challenge.startDate is DateTime
        ? challenge.startDate
        : DateTime.tryParse(challenge.startDate.toString());

    if (startDate == null) return 0.0;

    final now = DateTime.now();
    final daysPassed = now.difference(startDate).inDays;
    final totalDays = challenge.duration as int;

    return (daysPassed / totalDays).clamp(0.0, 1.0);
  }

  int _calculateDaysLeft() {
    if (challenge.startDate == null || challenge.duration == null) return 0;

    final startDate = challenge.startDate is DateTime
        ? challenge.startDate
        : DateTime.tryParse(challenge.startDate.toString());

    if (startDate == null) return 0;

    final endDate = startDate.add(Duration(days: challenge.duration as int));
    final now = DateTime.now();

    return endDate.difference(now).inDays.clamp(0, challenge.duration as int);
  }
}
