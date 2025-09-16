import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/challenges_controller.dart';
import '../widgets/widgets.dart';

class ChallengesView extends ConsumerStatefulWidget {
  const ChallengesView({super.key});

  @override
  ConsumerState<ChallengesView> createState() => _ChallengesViewState();
}

class _ChallengesViewState extends ConsumerState<ChallengesView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Charger les données
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(challengesControllerProvider.notifier).loadAvailableChallenges();
      ref.read(challengesControllerProvider.notifier).loadUserChallenges();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challengesState = ref.watch(challengesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Défis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Découvrir', icon: Icon(Icons.explore_outlined)),
            Tab(text: 'Mes défis', icon: Icon(Icons.emoji_events_outlined)),
            Tab(text: 'Créer', icon: Icon(Icons.add_circle_outline)),
          ],
        ),
      ),
      body: challengesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : challengesState.error != null
          ? CustomErrorWidget(
              error: challengesState.error!,
              onRetry: () {
                ref
                    .read(challengesControllerProvider.notifier)
                    .loadAvailableChallenges();
                ref
                    .read(challengesControllerProvider.notifier)
                    .loadUserChallenges();
              },
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDiscoverTab(),
                _buildMyChallengesTab(),
                _buildCreateTab(),
              ],
            ),
    );
  }

  Widget _buildDiscoverTab() {
    final challengesState = ref.watch(challengesControllerProvider);
    var challenges = challengesState.availableChallenges;

    // Filtrer par catégorie si nécessaire
    if (_selectedCategory != 'all') {
      challenges = challenges
          .where(
            (c) =>
                c.content['category'] == _selectedCategory ||
                c.typeId == _selectedCategory,
          )
          .toList();
    }

    return Column(
      children: [
        // Barre de recherche et filtres
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Recherche
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un défi...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                onChanged: (query) {
                  ref
                      .read(challengesControllerProvider.notifier)
                      .searchChallenges(query);
                },
              ),

              const SizedBox(height: 12),

              // Filtres de catégories
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('all', 'Tous'),
                    const SizedBox(width: 8),
                    ...challengesState.categories.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildCategoryChip(category, category),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Liste des défis
        Expanded(
          child: challenges.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun défi trouvé',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Essayez de modifier vos filtres',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: challenges.length,
                  itemBuilder: (context, index) {
                    final challenge = challenges[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ChallengeDiscoveryCard(
                        challenge: challenge,
                        onJoin: () => _joinChallenge(challenge.id),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMyChallengesTab() {
    final challengesState = ref.watch(challengesControllerProvider);
    final activeChallenges = challengesState.userChallenges
        .where((c) => c.status == 'active')
        .toList();
    final completedChallenges = challengesState.userChallenges
        .where((c) => c.status == 'completed')
        .toList();

    return challengesState.userChallenges.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 80,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun défi rejoint',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Découvrez et rejoignez des défis pour améliorer vos habitudes !',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(0),
                  icon: const Icon(Icons.explore),
                  label: const Text('Découvrir les défis'),
                ),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Défis actifs
                if (activeChallenges.isNotEmpty) ...[
                  Text(
                    'Défis en cours (${activeChallenges.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...activeChallenges.map(
                    (challenge) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ChallengeProgressCard(
                        challenge: challenge,
                        onTap: () => _showChallengeDetails(challenge),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Défis complétés
                if (completedChallenges.isNotEmpty) ...[
                  Text(
                    'Défis complétés (${completedChallenges.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...completedChallenges.map(
                    (challenge) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ChallengeCompletedCard(
                        challenge: challenge,
                        onTap: () => _showChallengeDetails(challenge),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
  }

  Widget _buildCreateTab() {
    return const CreateChallengeForm();
  }

  Widget _buildCategoryChip(String value, String label) {
    final isSelected = _selectedCategory == value;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _selectedCategory = value;
        });
      },
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ChallengeFilterSheet(),
    );
  }

  void _joinChallenge(String challengeId) async {
    await ref
        .read(challengesControllerProvider.notifier)
        .joinChallenge(challengeId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Défi rejoint avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showChallengeDetails(dynamic challenge) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ChallengeDetailsSheet(challenge: challenge),
    );
  }
}

// Widget pour créer un défi
class CreateChallengeForm extends ConsumerStatefulWidget {
  const CreateChallengeForm({super.key});

  @override
  ConsumerState<CreateChallengeForm> createState() =>
      _CreateChallengeFormState();
}

class _CreateChallengeFormState extends ConsumerState<CreateChallengeForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();

  String _selectedCategory = 'focus';
  String _selectedDifficulty = 'medium';
  int _duration = 7; // jours
  bool _isPublic = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Créer un défi personnalisé',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            // Titre
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre du défi',
                border: OutlineInputBorder(),
                helperText: 'Ex: "30 jours sans réseaux sociaux"',
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Veuillez saisir un titre';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                helperText: 'Décrivez votre défi et ses objectifs',
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Veuillez saisir une description';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Catégorie
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'focus', child: Text('Focus')),
                DropdownMenuItem(
                  value: 'social_media',
                  child: Text('Réseaux sociaux'),
                ),
                DropdownMenuItem(
                  value: 'screen_time',
                  child: Text('Temps d\'écran'),
                ),
                DropdownMenuItem(
                  value: 'physical',
                  child: Text('Activité physique'),
                ),
                DropdownMenuItem(
                  value: 'mindfulness',
                  child: Text('Pleine conscience'),
                ),
                DropdownMenuItem(
                  value: 'productivity',
                  child: Text('Productivité'),
                ),
                DropdownMenuItem(value: 'other', child: Text('Autre')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Difficulté
            DropdownButtonFormField<String>(
              value: _selectedDifficulty,
              decoration: const InputDecoration(
                labelText: 'Difficulté',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'easy', child: Text('Facile')),
                DropdownMenuItem(value: 'medium', child: Text('Moyen')),
                DropdownMenuItem(value: 'hard', child: Text('Difficile')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedDifficulty = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Durée
            Text(
              'Durée: $_duration jours',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Slider(
              value: _duration.toDouble(),
              min: 1,
              max: 365,
              divisions: 52, // Semaines
              onChanged: (value) {
                setState(() {
                  _duration = value.round();
                });
              },
            ),

            const SizedBox(height: 16),

            // Objectif/Target
            TextFormField(
              controller: _targetController,
              decoration: const InputDecoration(
                labelText: 'Objectif numérique (optionnel)',
                border: OutlineInputBorder(),
                helperText: 'Ex: 120 (pour 120 minutes par jour)',
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // Public/Privé
            SwitchListTile(
              title: const Text('Défi public'),
              subtitle: Text(
                _isPublic
                    ? 'Visible par tous les utilisateurs'
                    : 'Visible uniquement par vous',
              ),
              value: _isPublic,
              onChanged: (value) {
                setState(() {
                  _isPublic = value;
                });
              },
            ),

            const SizedBox(height: 32),

            // Bouton de création
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createChallenge,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Créer le défi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createChallenge() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref
          .read(challengesControllerProvider.notifier)
          .createChallenge(
            title: _titleController.text,
            description: _descriptionController.text,
            category: _selectedCategory,
            difficulty: _selectedDifficulty,
            type: 'custom', // Type par défaut
            target: int.tryParse(_targetController.text) ?? 100,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Défi créé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        _titleController.clear();
        _descriptionController.clear();
        _targetController.clear();
      }
    }
  }
}
