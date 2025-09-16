import 'package:flutter/material.dart';

class ChallengeFilterSheet extends StatefulWidget {
  const ChallengeFilterSheet({super.key});

  @override
  State<ChallengeFilterSheet> createState() => _ChallengeFilterSheetState();
}

class _ChallengeFilterSheetState extends State<ChallengeFilterSheet> {
  String _selectedCategory = 'all';
  String _selectedDifficulty = 'all';
  RangeValues _durationRange = const RangeValues(1, 30);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 24),

          // Catégorie
          Text('Catégorie', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Tous'),
                selected: _selectedCategory == 'all',
                onSelected: (selected) =>
                    setState(() => _selectedCategory = 'all'),
              ),
              FilterChip(
                label: const Text('Focus'),
                selected: _selectedCategory == 'focus',
                onSelected: (selected) =>
                    setState(() => _selectedCategory = 'focus'),
              ),
              FilterChip(
                label: const Text('Réseaux sociaux'),
                selected: _selectedCategory == 'social_media',
                onSelected: (selected) =>
                    setState(() => _selectedCategory = 'social_media'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Appliquer les filtres
                    Navigator.of(context).pop();
                  },
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
