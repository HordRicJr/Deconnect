import 'package:flutter/material.dart';

class ChallengeDetailsSheet extends StatelessWidget {
  final dynamic challenge;

  const ChallengeDetailsSheet({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title ?? 'Défi sans titre',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        challenge.description ??
                            'Aucune description disponible.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),

                      const SizedBox(height: 24),

                      // Informations du défi
                      _buildInfoRow(
                        'Catégorie',
                        challenge.category ?? 'Non définie',
                      ),
                      _buildInfoRow(
                        'Difficulté',
                        challenge.difficulty ?? 'Non définie',
                      ),
                      _buildInfoRow(
                        'Durée',
                        '${challenge.duration ?? 0} jours',
                      ),
                      if (challenge.target != null)
                        _buildInfoRow('Objectif', '${challenge.target}'),

                      const SizedBox(height: 24),

                      // Actions
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Action selon le statut du défi
                          },
                          child: Text(_getActionText()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  String _getActionText() {
    switch (challenge.status) {
      case 'active':
        return 'Voir les détails';
      case 'completed':
        return 'Revoir le défi';
      default:
        return 'Rejoindre le défi';
    }
  }
}
