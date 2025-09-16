import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/challenge.dart';
import '../models/user_challenge.dart';
import '../services/services.dart';
import '../providers/providers.dart';

// État des défis
class ChallengesState {
  final List<Challenge> challenges;
  final List<Challenge> availableChallenges;
  final List<UserChallenge> userChallenges;
  final List<String> categories;
  final bool isLoading;
  final String? error;
  final String selectedFilter;

  const ChallengesState({
    this.challenges = const [],
    this.availableChallenges = const [],
    this.userChallenges = const [],
    this.categories = const [
      'All',
      'Fitness',
      'Mindfulness',
      'Productivity',
      'Social',
    ],
    this.isLoading = false,
    this.error,
    this.selectedFilter = 'all',
  });

  ChallengesState copyWith({
    List<Challenge>? challenges,
    List<Challenge>? availableChallenges,
    List<UserChallenge>? userChallenges,
    List<String>? categories,
    bool? isLoading,
    String? error,
    String? selectedFilter,
  }) {
    return ChallengesState(
      challenges: challenges ?? this.challenges,
      availableChallenges: availableChallenges ?? this.availableChallenges,
      userChallenges: userChallenges ?? this.userChallenges,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}

// Controller des défis
class ChallengesController extends StateNotifier<ChallengesState> {
  ChallengesController(this._appService, this._authService)
    : super(const ChallengesState());

  final AppService _appService;
  final AuthService _authService;

  // Charger tous les défis
  Future<void> loadChallenges() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final challenges = await _appService.challenge.getActiveChallenges();
      List<UserChallenge> userChallenges = [];

      if (_authService.isAuthenticated) {
        final userId = _authService.currentUser!.id;
        userChallenges = await _appService.challenge.getUserChallenges(userId);
      }

      state = state.copyWith(
        challenges: challenges,
        userChallenges: userChallenges,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des défis: $e',
      );
    }
  }

  // Filtrer les défis
  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  // Obtenir les défis filtrés
  List<Challenge> get filteredChallenges {
    switch (state.selectedFilter) {
      case 'joined':
        final joinedIds = state.userChallenges
            .map((uc) => uc.challengeId)
            .toSet();
        return state.challenges.where((c) => joinedIds.contains(c.id)).toList();
      case 'available':
        final joinedIds = state.userChallenges
            .map((uc) => uc.challengeId)
            .toSet();
        return state.challenges
            .where((c) => !joinedIds.contains(c.id))
            .toList();
      case 'completed':
        final completedIds = state.userChallenges
            .where((uc) => uc.status == 'completed')
            .map((uc) => uc.challengeId)
            .toSet();
        return state.challenges
            .where((c) => completedIds.contains(c.id))
            .toList();
      default:
        return state.challenges;
    }
  }

  // Rejoindre un défi
  Future<void> joinChallenge(String challengeId) async {
    if (!_authService.isAuthenticated) {
      state = state.copyWith(
        error: 'Vous devez être connecté pour rejoindre un défi',
      );
      return;
    }

    try {
      final userId = _authService.currentUser!.id;
      await _appService.challenge.joinChallenge(challengeId, userId);

      // Recharger les défis utilisateur
      await _loadUserChallenges();
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur lors de l\'inscription au défi: $e',
      );
    }
  }

  // Quitter un défi
  Future<void> leaveChallenge(String challengeId) async {
    if (!_authService.isAuthenticated) return;

    try {
      final userId = _authService.currentUser!.id;
      await _appService.challenge.leaveChallenge(challengeId, userId);

      // Recharger les défis utilisateur
      await _loadUserChallenges();
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la sortie du défi: $e');
    }
  }

  // Marquer un défi comme terminé
  Future<void> completeChallenge(String challengeId) async {
    if (!_authService.isAuthenticated) return;

    try {
      final userId = _authService.currentUser!.id;

      // Trouver le UserChallenge
      final userChallenge = state.userChallenges.firstWhere(
        (uc) => uc.challengeId == challengeId,
      );

      await _appService.challenge.updateUserChallenge(
        userChallenge.challengeId,
        userChallenge.userId,
        {
          'status': 'completed',
          'completed_at': DateTime.now().toIso8601String(),
        },
      );

      // Recharger les défis utilisateur
      await _loadUserChallenges();
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la completion du défi: $e');
    }
  }

  // Mettre à jour le progrès d'un défi
  Future<void> updateProgress(String challengeId, int progress) async {
    if (!_authService.isAuthenticated) return;

    try {
      final userChallenge = state.userChallenges.firstWhere(
        (uc) => uc.challengeId == challengeId,
      );

      await _appService.challenge.updateUserChallenge(
        userChallenge.challengeId,
        userChallenge.userId,
        {'progress': progress, 'updated_at': DateTime.now().toIso8601String()},
      );

      // Recharger les défis utilisateur
      await _loadUserChallenges();
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur lors de la mise à jour du progrès: $e',
      );
    }
  }

  // Obtenir le défi par ID
  Challenge? getChallengeById(String id) {
    try {
      return state.challenges.firstWhere((challenge) => challenge.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obtenir le UserChallenge par challenge ID
  UserChallenge? getUserChallengeByChallenge(String challengeId) {
    try {
      return state.userChallenges.firstWhere(
        (uc) => uc.challengeId == challengeId,
      );
    } catch (e) {
      return null;
    }
  }

  // Vérifier si l'utilisateur a rejoint un défi
  bool hasJoinedChallenge(String challengeId) {
    return state.userChallenges.any((uc) => uc.challengeId == challengeId);
  }

  // Calculer le pourcentage de completion d'un défi
  double getChallengeCompletionPercentage(String challengeId) {
    final userChallenge = getUserChallengeByChallenge(challengeId);
    final challenge = getChallengeById(challengeId);

    if (userChallenge == null || challenge == null) return 0.0;

    final target = challenge.content['target'] as int? ?? 100;
    final currentProgress = userChallenge.progress['value'] as int? ?? 0;
    return (currentProgress / target * 100).clamp(0.0, 100.0);
  }

  // Charger les défis utilisateur seulement
  Future<void> _loadUserChallenges() async {
    if (!_authService.isAuthenticated) return;

    try {
      final userId = _authService.currentUser!.id;
      final userChallenges = await _appService.challenge.getUserChallenges(
        userId,
      );

      state = state.copyWith(userChallenges: userChallenges);
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur lors du chargement des défis utilisateur: $e',
      );
    }
  }

  // Rechercher des défis
  Future<void> searchChallenges(String query) async {
    if (query.isEmpty) {
      await loadChallenges();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final challenges = await _appService.challenge.searchChallenges(query);

      state = state.copyWith(challenges: challenges, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la recherche: $e',
      );
    }
  }

  // Effacer l'erreur
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Charger les défis disponibles
  Future<void> loadAvailableChallenges() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final challenges = await _appService.challenge.getActiveChallenges();

      // Filtrer les défis non rejoints si l'utilisateur est connecté
      List<Challenge> availableChallenges = challenges;
      if (_authService.isAuthenticated) {
        final userId = _authService.currentUser!.id;
        final userChallenges = await _appService.challenge.getUserChallenges(
          userId,
        );
        final joinedIds = userChallenges.map((uc) => uc.challengeId).toSet();
        availableChallenges = challenges
            .where((c) => !joinedIds.contains(c.id))
            .toList();
      }

      state = state.copyWith(challenges: availableChallenges, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des défis disponibles: $e',
      );
    }
  }

  // Charger les défis utilisateur
  Future<void> loadUserChallenges() async {
    if (!_authService.isAuthenticated) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final userId = _authService.currentUser!.id;
      final userChallenges = await _appService.challenge.getUserChallenges(
        userId,
      );

      state = state.copyWith(userChallenges: userChallenges, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des défis utilisateur: $e',
      );
    }
  }

  // Créer un défi
  Future<void> createChallenge({
    required String title,
    required String description,
    required String category,
    required String difficulty,
    required int target,
    required String type,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_authService.isAuthenticated) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final challenge = Challenge(
        id: '', // Sera généré par le service
        typeId: type,
        title: title,
        description: description,
        difficulty: int.tryParse(difficulty) ?? 1,
        estimatedDuration: target,
        content: {
          'target': target,
          'category': category,
          'rules': [],
          ...?metadata,
        },
        createdAt: DateTime.now(),
      );

      await _appService.challenge.createChallenge(challenge);

      // Recharger les défis
      await loadChallenges();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la création du défi: $e',
      );
    }
  }
}

// Provider du controller des défis
final challengesControllerProvider =
    StateNotifierProvider<ChallengesController, ChallengesState>((ref) {
      final appService = ref.watch(appServiceProvider);
      final authService = ref.watch(authServiceProvider);
      return ChallengesController(appService, authService);
    });
