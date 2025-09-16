import 'package:flutter/material.dart';

class BadgeCard extends StatelessWidget {
  final dynamic badge;
  final VoidCallback? onTap;

  const BadgeCard({super.key, required this.badge, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône du badge
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getBadgeColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getBadgeIcon(), size: 32, color: _getBadgeColor()),
              ),

              const SizedBox(height: 12),

              // Nom du badge
              Text(
                badge.name ?? 'Badge',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Description
              Text(
                badge.description ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Date d'obtention
              if (badge.earnedAt != null)
                Text(
                  _formatDate(badge.earnedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getBadgeIcon() {
    switch (badge.type?.toLowerCase()) {
      case 'focus':
        return Icons.timer;
      case 'challenge':
        return Icons.emoji_events;
      case 'social':
        return Icons.people;
      case 'streak':
        return Icons.local_fire_department;
      case 'level':
        return Icons.trending_up;
      default:
        return Icons.military_tech;
    }
  }

  Color _getBadgeColor() {
    switch (badge.rarity?.toLowerCase()) {
      case 'common':
        return Colors.grey;
      case 'rare':
        return Colors.blue;
      case 'epic':
        return Colors.purple;
      case 'legendary':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';

    final dateTime = date is DateTime
        ? date
        : DateTime.tryParse(date.toString());
    if (dateTime == null) return '';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
