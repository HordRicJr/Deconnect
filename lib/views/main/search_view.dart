import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/search_controller.dart';
import '../widgets/widgets.dart';

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: const InputDecoration(
            hintText: 'Rechercher...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onSubmitted: (query) {
            if (query.isNotEmpty) {
              ref.read(searchControllerProvider.notifier).search(query);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              ref.read(searchControllerProvider.notifier).clearSearch();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres de recherche
          _buildSearchFilters(),

          // Résultats de recherche
          Expanded(
            child: searchState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : searchState.results.isEmpty && searchState.query.isNotEmpty
                ? _buildNoResults()
                : searchState.query.isEmpty
                ? _buildRecentSearches()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilters() {
    final searchState = ref.watch(searchControllerProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('Tout'),
              selected: searchState.filter == SearchFilter.all,
              onSelected: (selected) {
                if (selected) {
                  ref
                      .read(searchControllerProvider.notifier)
                      .setFilter(SearchFilter.all);
                }
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Événements'),
              selected: searchState.filter == SearchFilter.events,
              onSelected: (selected) {
                if (selected) {
                  ref
                      .read(searchControllerProvider.notifier)
                      .setFilter(SearchFilter.events);
                }
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Organisations'),
              selected: searchState.filter == SearchFilter.organizations,
              onSelected: (selected) {
                if (selected) {
                  ref
                      .read(searchControllerProvider.notifier)
                      .setFilter(SearchFilter.organizations);
                }
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Utilisateurs'),
              selected: searchState.filter == SearchFilter.users,
              onSelected: (selected) {
                if (selected) {
                  ref
                      .read(searchControllerProvider.notifier)
                      .setFilter(SearchFilter.users);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final searchState = ref.watch(searchControllerProvider);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: searchState.results.length,
      itemBuilder: (context, index) {
        final result = searchState.results[index];

        switch (result.type) {
          case SearchResultType.event:
            return _buildEventResult(result);
          case SearchResultType.organization:
            return _buildOrganizationResult(result);
          case SearchResultType.user:
            return _buildUserResult(result);
        }
      },
    );
  }

  Widget _buildEventResult(SearchResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.event)),
        title: Text(result.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.subtitle != null) Text(result.subtitle!),
            if (result.location != null)
              Text(
                result.location!,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigation vers l'événement
        },
      ),
    );
  }

  Widget _buildOrganizationResult(SearchResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: result.imageUrl != null
              ? NetworkImage(result.imageUrl!)
              : null,
          child: result.imageUrl == null ? const Icon(Icons.business) : null,
        ),
        title: Text(result.title),
        subtitle: result.subtitle != null ? Text(result.subtitle!) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigation vers l'organisation
        },
      ),
    );
  }

  Widget _buildUserResult(SearchResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: result.imageUrl != null
              ? NetworkImage(result.imageUrl!)
              : null,
          child: result.imageUrl == null ? const Icon(Icons.person) : null,
        ),
        title: Text(result.title),
        subtitle: result.subtitle != null ? Text(result.subtitle!) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigation vers le profil utilisateur
        },
      ),
    );
  }

  Widget _buildNoResults() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Aucun résultat trouvé',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            'Essayez avec d\'autres mots-clés',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    final searchState = ref.watch(searchControllerProvider);

    if (searchState.recentSearches.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Commencez votre recherche',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'Trouvez des événements, organisations et utilisateurs',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Recherches récentes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: searchState.recentSearches.length,
            itemBuilder: (context, index) {
              final search = searchState.recentSearches[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(search),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    ref
                        .read(searchControllerProvider.notifier)
                        .removeRecentSearch(search);
                  },
                ),
                onTap: () {
                  _searchController.text = search;
                  ref.read(searchControllerProvider.notifier).search(search);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// Enums pour les types de résultats et filtres
enum SearchResultType { event, organization, user }

enum SearchFilter { all, events, organizations, users }

// Modèle pour les résultats de recherche
class SearchResult {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? location;
  final SearchResultType type;

  SearchResult({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.location,
    required this.type,
  });
}
