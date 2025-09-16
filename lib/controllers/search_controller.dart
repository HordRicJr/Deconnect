import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../views/main/search_view.dart';

// État de la recherche
class SearchState {
  final String query;
  final List<SearchResult> results;
  final List<String> recentSearches;
  final SearchFilter filter;
  final bool isLoading;
  final String? error;

  SearchState({
    this.query = '',
    this.results = const [],
    this.recentSearches = const [],
    this.filter = SearchFilter.all,
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    List<SearchResult>? results,
    List<String>? recentSearches,
    SearchFilter? filter,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      recentSearches: recentSearches ?? this.recentSearches,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Contrôleur de recherche
class SearchController extends StateNotifier<SearchState> {
  SearchController() : super(SearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    state = state.copyWith(query: query, isLoading: true, error: null);

    try {
      // Ajouter à l'historique
      _addToRecentSearches(query);

      // Simuler une recherche (à remplacer par l'appel API réel)
      await Future.delayed(const Duration(milliseconds: 500));

      final results = await _performSearch(query, state.filter);

      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(SearchFilter filter) {
    state = state.copyWith(filter: filter);

    // Si une recherche est active, relancer avec le nouveau filtre
    if (state.query.isNotEmpty) {
      search(state.query);
    }
  }

  void clearSearch() {
    state = state.copyWith(query: '', results: [], error: null);
  }

  void removeRecentSearch(String search) {
    final updatedSearches = List<String>.from(state.recentSearches);
    updatedSearches.remove(search);
    state = state.copyWith(recentSearches: updatedSearches);
  }

  void _addToRecentSearches(String query) {
    final updatedSearches = List<String>.from(state.recentSearches);

    // Supprimer si déjà présent
    updatedSearches.remove(query);

    // Ajouter au début
    updatedSearches.insert(0, query);

    // Limiter à 10 recherches récentes
    if (updatedSearches.length > 10) {
      updatedSearches.removeLast();
    }

    state = state.copyWith(recentSearches: updatedSearches);
  }

  Future<List<SearchResult>> _performSearch(
    String query,
    SearchFilter filter,
  ) async {
    // Simuler des résultats de recherche
    final List<SearchResult> allResults = [
      // Événements
      SearchResult(
        id: '1',
        title: 'Méditation en plein air',
        subtitle: 'Session de méditation dans le parc',
        location: 'Parc de la Tête d\'Or',
        type: SearchResultType.event,
      ),
      SearchResult(
        id: '2',
        title: 'Atelier déconnexion digitale',
        subtitle: 'Apprendre à mieux gérer son temps d\'écran',
        location: 'Centre culturel',
        type: SearchResultType.event,
      ),

      // Organisations
      SearchResult(
        id: '3',
        title: 'Digital Detox Lyon',
        subtitle: 'Association pour le bien-être numérique',
        type: SearchResultType.organization,
      ),
      SearchResult(
        id: '4',
        title: 'Mindful Tech',
        subtitle: 'Communauté tech consciente',
        type: SearchResultType.organization,
      ),

      // Utilisateurs
      SearchResult(
        id: '5',
        title: 'Marie Dupont',
        subtitle: 'Passionnée de méditation',
        type: SearchResultType.user,
      ),
      SearchResult(
        id: '6',
        title: 'Jean Martin',
        subtitle: 'Coach en bien-être digital',
        type: SearchResultType.user,
      ),
    ];

    // Filtrer les résultats selon le filtre actif
    List<SearchResult> filteredResults;
    switch (filter) {
      case SearchFilter.events:
        filteredResults = allResults
            .where((result) => result.type == SearchResultType.event)
            .toList();
        break;
      case SearchFilter.organizations:
        filteredResults = allResults
            .where((result) => result.type == SearchResultType.organization)
            .toList();
        break;
      case SearchFilter.users:
        filteredResults = allResults
            .where((result) => result.type == SearchResultType.user)
            .toList();
        break;
      case SearchFilter.all:
      default:
        filteredResults = allResults;
    }

    // Filtrer par query (simulation simple)
    final queryLower = query.toLowerCase();
    return filteredResults
        .where(
          (result) =>
              result.title.toLowerCase().contains(queryLower) ||
              (result.subtitle?.toLowerCase().contains(queryLower) ?? false),
        )
        .toList();
  }
}

// Provider pour le contrôleur de recherche
final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchState>((ref) {
      return SearchController();
    });
