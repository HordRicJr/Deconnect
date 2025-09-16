import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/services.dart';
import '../providers/providers.dart';

// État des événements IRL
class IrlEventsState {
  final List<IrlEvent> events;
  final List<IrlEvent> myEvents;
  final IrlEvent? selectedEvent;
  final List<Organization> organizations;
  final bool isLoading;
  final String? error;

  const IrlEventsState({
    this.events = const [],
    this.myEvents = const [],
    this.selectedEvent,
    this.organizations = const [],
    this.isLoading = false,
    this.error,
  });

  IrlEventsState copyWith({
    List<IrlEvent>? events,
    List<IrlEvent>? myEvents,
    IrlEvent? selectedEvent,
    List<Organization>? organizations,
    bool? isLoading,
    String? error,
  }) {
    return IrlEventsState(
      events: events ?? this.events,
      myEvents: myEvents ?? this.myEvents,
      selectedEvent: selectedEvent ?? this.selectedEvent,
      organizations: organizations ?? this.organizations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Controller des événements IRL
class IrlEventsController extends StateNotifier<IrlEventsState> {
  IrlEventsController(this._appService, this._authService)
    : super(const IrlEventsState());

  final AppService _appService;
  final AuthService _authService;

  // Charger les événements à proximité
  Future<void> loadNearbyEvents({
    double? latitude,
    double? longitude,
    double radiusKm = 50.0,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Utiliser getUpcomingEvents comme alternative à getNearbyEvents
      final events = await _appService.irlEvent.getUpcomingEvents(limit: 20);

      state = state.copyWith(events: events, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des événements: $e',
      );
    }
  }

  // Charger mes événements
  Future<void> loadMyEvents() async {
    if (!_authService.isAuthenticated) {
      state = state.copyWith(error: 'Vous devez être connecté');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final userId = _authService.currentUser!.id;
      final events = await _appService.irlEvent.getUserEvents(userId);

      state = state.copyWith(myEvents: events, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement de vos événements: $e',
      );
    }
  }

  // Créer un nouvel événement
  Future<bool> createEvent({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required String location,
    required double latitude,
    required double longitude,
    required String category,
    int? maxParticipants,
    bool isPublic = true,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_authService.isAuthenticated) {
      state = state.copyWith(error: 'Vous devez être connecté');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final userId = _authService.currentUser!.id;

      final newEvent = IrlEvent(
        id: '', // Sera généré par le service
        title: title,
        description: description,
        eventType: category,
        category: category,
        startsAt: startTime,
        endsAt: endTime,
        startTime: startTime,
        locationName: location,
        latitude: latitude,
        longitude: longitude,
        maxParticipants: maxParticipants,
        organizerId: userId,
        isPublic: isPublic,
        qrCode: '', // Sera généré par le service
        createdAt: DateTime.now(),
      );

      final event = await _appService.irlEvent.createEvent(newEvent);

      // Ajouter l'événement à mes événements
      state = state.copyWith(
        myEvents: [...state.myEvents, event],
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la création: $e',
      );
      return false;
    }
  }

  // S'inscrire à un événement
  Future<bool> joinEvent(String eventId) async {
    if (!_authService.isAuthenticated) {
      state = state.copyWith(error: 'Vous devez être connecté');
      return false;
    }

    try {
      final userId = _authService.currentUser!.id;

      await _appService.irlEvent.joinEvent(eventId, userId);

      // Mettre à jour l'événement dans la liste
      _updateEventInList(
        eventId,
        (event) =>
            event.copyWith(participantsCount: event.participantsCount + 1),
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de l\'inscription: $e');
      return false;
    }
  }

  // Se désinscrire d'un événement
  Future<bool> leaveEvent(String eventId) async {
    if (!_authService.isAuthenticated) {
      state = state.copyWith(error: 'Vous devez être connecté');
      return false;
    }

    try {
      final userId = _authService.currentUser!.id;

      await _appService.irlEvent.leaveEvent(eventId, userId);

      // Mettre à jour l'événement dans la liste
      _updateEventInList(
        eventId,
        (event) =>
            event.copyWith(participantsCount: event.participantsCount - 1),
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la désinscription: $e');
      return false;
    }
  }

  // Obtenir les détails d'un événement
  Future<void> loadEventDetails(String eventId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final event = await _appService.irlEvent.getEvent(eventId);

      state = state.copyWith(selectedEvent: event, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des détails: $e',
      );
    }
  }

  // Obtenir les participants d'un événement
  Future<List<Profile>> getEventParticipants(String eventId) async {
    try {
      final participants = await _appService.irlEvent.getEventParticipants(
        eventId,
      );
      return participants.map((p) => Profile.fromJson(p)).toList();
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur lors du chargement des participants: $e',
      );
      return [];
    }
  }

  // Filtrer les événements
  void filterEvents({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    bool? hasAvailableSpots,
  }) {
    List<IrlEvent> filtered = List.from(state.events);

    if (category != null && category.isNotEmpty) {
      filtered = filtered.where((e) => e.category == category).toList();
    }

    if (startDate != null) {
      filtered = filtered
          .where(
            (e) =>
                e.startTime?.isAfter(startDate) ??
                e.startsAt.isAfter(startDate),
          )
          .toList();
    }

    if (endDate != null) {
      filtered = filtered
          .where(
            (e) =>
                e.startTime?.isBefore(endDate) ?? e.startsAt.isBefore(endDate),
          )
          .toList();
    }

    if (hasAvailableSpots == true) {
      filtered = filtered
          .where(
            (e) =>
                e.maxParticipants == null ||
                e.participantsCount < e.maxParticipants!,
          )
          .toList();
    }

    state = state.copyWith(events: filtered);
  }

  // Rechercher des événements
  Future<void> searchEvents(String query) async {
    if (query.isEmpty) {
      await loadNearbyEvents();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final events = await _appService.irlEvent.searchEvents(query);

      state = state.copyWith(events: events, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la recherche: $e',
      );
    }
  }

  // Obtenir les catégories d'événements
  List<String> getEventCategories() {
    return [
      'Tous',
      'Sport',
      'Culture',
      'Technologie',
      'Bien-être',
      'Social',
      'Business',
    ];
  }

  // Supprimer un événement (pour le créateur)
  Future<bool> deleteEvent(String eventId) async {
    if (!_authService.isAuthenticated) {
      state = state.copyWith(error: 'Vous devez être connecté');
      return false;
    }

    try {
      await _appService.irlEvent.deleteEvent(eventId);

      // Retirer l'événement des listes
      state = state.copyWith(
        events: state.events.where((e) => e.id != eventId).toList(),
        myEvents: state.myEvents.where((e) => e.id != eventId).toList(),
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la suppression: $e');
      return false;
    }
  }

  // Mettre à jour un événement
  Future<bool> updateEvent(String eventId, Map<String, dynamic> updates) async {
    if (!_authService.isAuthenticated) {
      state = state.copyWith(error: 'Vous devez être connecté');
      return false;
    }

    try {
      final updatedEvent = await _appService.irlEvent.updateEvent(
        eventId,
        updates,
      );

      // Mettre à jour dans les listes
      _updateEventInList(eventId, (event) => updatedEvent);

      if (state.selectedEvent?.id == eventId) {
        state = state.copyWith(selectedEvent: updatedEvent);
      }

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la mise à jour: $e');
      return false;
    }
  }

  // Obtenir les événements recommandés
  Future<void> loadRecommendedEvents() async {
    if (!_authService.isAuthenticated) return;

    try {
      final events = await _appService.irlEvent
          .getEvents(); // Utiliser getEvents au lieu de getRecommendedEvents

      state = state.copyWith(events: events);
    } catch (e) {
      state = state.copyWith(
        error: 'Erreur lors du chargement des recommandations: $e',
      );
    }
  }

  // Méthodes utilitaires
  void _updateEventInList(String eventId, IrlEvent Function(IrlEvent) updater) {
    final updatedEvents = state.events.map((event) {
      return event.id == eventId ? updater(event) : event;
    }).toList();

    final updatedMyEvents = state.myEvents.map((event) {
      return event.id == eventId ? updater(event) : event;
    }).toList();

    state = state.copyWith(events: updatedEvents, myEvents: updatedMyEvents);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearSelectedEvent() {
    state = state.copyWith(selectedEvent: null);
  }
}

// État des organisations
class OrganizationsState {
  final List<Organization> organizations;
  final List<Organization> myOrganizations;
  final Organization? selectedOrganization;
  final bool isLoading;
  final String? error;

  const OrganizationsState({
    this.organizations = const [],
    this.myOrganizations = const [],
    this.selectedOrganization,
    this.isLoading = false,
    this.error,
  });

  OrganizationsState copyWith({
    List<Organization>? organizations,
    List<Organization>? myOrganizations,
    Organization? selectedOrganization,
    bool? isLoading,
    String? error,
  }) {
    return OrganizationsState(
      organizations: organizations ?? this.organizations,
      myOrganizations: myOrganizations ?? this.myOrganizations,
      selectedOrganization: selectedOrganization ?? this.selectedOrganization,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Controller des organisations
class OrganizationsController extends StateNotifier<OrganizationsState> {
  OrganizationsController(this._appService, this._authService)
    : super(const OrganizationsState());

  final AppService _appService;
  final AuthService _authService;

  // Charger les organisations
  Future<void> loadOrganizations() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final organizations = await _appService.organization.getOrganizations();

      state = state.copyWith(organizations: organizations, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement: $e',
      );
    }
  }

  // Charger mes organisations
  Future<void> loadMyOrganizations() async {
    if (!_authService.isAuthenticated) return;

    try {
      final organizations = await _appService.organization.getOrganizations();

      state = state.copyWith(myOrganizations: organizations);
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors du chargement: $e');
    }
  }

  // Créer une organisation
  Future<bool> createOrganization({
    required String name,
    required String description,
    required String type,
    String? website,
    String? location,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_authService.isAuthenticated) {
      state = state.copyWith(error: 'Vous devez être connecté');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final organizationData = Organization(
        id: '', // sera généré par le service
        name: name,
        slug: name.toLowerCase().replaceAll(' ', '-'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final organization = await _appService.organization.createOrganization(
        organizationData,
      );

      state = state.copyWith(
        myOrganizations: [...state.myOrganizations, organization],
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la création: $e',
      );
      return false;
    }
  }

  // Rejoindre une organisation
  Future<bool> joinOrganization(String organizationId) async {
    if (!_authService.isAuthenticated) {
      state = state.copyWith(error: 'Vous devez être connecté');
      return false;
    }

    try {
      final userId = _authService.currentUser!.id;

      await _appService.organization.joinOrganization(userId, organizationId);

      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de l\'adhésion: $e');
      return false;
    }
  }

  // Obtenir les détails d'une organisation
  Future<void> loadOrganizationDetails(String organizationId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final organization = await _appService.organization.getOrganization(
        organizationId,
      );

      state = state.copyWith(
        selectedOrganization: organization,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final irlEventsControllerProvider =
    StateNotifierProvider<IrlEventsController, IrlEventsState>((ref) {
      final appService = ref.watch(appServiceProvider);
      final authService = ref.watch(authServiceProvider);
      return IrlEventsController(appService, authService);
    });

final organizationsControllerProvider =
    StateNotifierProvider<OrganizationsController, OrganizationsState>((ref) {
      final appService = ref.watch(appServiceProvider);
      final authService = ref.watch(authServiceProvider);
      return OrganizationsController(appService, authService);
    });
