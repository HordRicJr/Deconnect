import 'package:flutter/material.dart';

class ActivityTile extends StatelessWidget {
  final Map<String, dynamic> activity;
  final bool showDivider;

  const ActivityTile({
    super.key,
    required this.activity,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: _getActivityColor().withOpacity(0.1),
            child: Icon(
              _getActivityIcon(),
              color: _getActivityColor(),
              size: 20,
            ),
          ),
          title: Text(
            activity['title'] ?? 'Activité',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(activity['description'] ?? ''),
          trailing: Text(
            _formatTime(activity['createdAt']),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }

  IconData _getActivityIcon() {
    switch (activity['type']) {
      case 'challenge_completed':
        return Icons.emoji_events;
      case 'focus_session':
        return Icons.timer;
      case 'event_joined':
        return Icons.event;
      case 'badge_earned':
        return Icons.military_tech;
      case 'level_up':
        return Icons.trending_up;
      default:
        return Icons.circle;
    }
  }

  Color _getActivityColor() {
    switch (activity['type']) {
      case 'challenge_completed':
        return Colors.orange;
      case 'focus_session':
        return Colors.blue;
      case 'event_joined':
        return Colors.green;
      case 'badge_earned':
        return Colors.purple;
      case 'level_up':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final activityTime = timestamp is DateTime
        ? timestamp
        : DateTime.tryParse(timestamp.toString());

    if (activityTime == null) return '';

    final difference = now.difference(activityTime);

    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays}j';
    }
  }
}
