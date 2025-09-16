import 'package:flutter/material.dart';

Widget FocusSessionView({String? sessionId}) {
  return Scaffold(
    appBar: AppBar(title: const Text('Session de Focus')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.center_focus_strong, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            sessionId != null ? 'Session ID: $sessionId' : 'Nouvelle session',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text('Vue de session de focus à implémenter'),
        ],
      ),
    ),
  );
}

Widget EventDetailView({required String eventId}) {
  return Scaffold(
    appBar: AppBar(title: const Text('Détail de l\'événement')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Événement ID: $eventId', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Vue détaillée d\'événement à implémenter'),
        ],
      ),
    ),
  );
}

Widget OrganizationDetailView({required String organizationId}) {
  return Scaffold(
    appBar: AppBar(title: const Text('Détail de l\'organisation')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.business, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Organisation ID: $organizationId',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text('Vue détaillée d\'organisation à implémenter'),
        ],
      ),
    ),
  );
}

Widget SearchView() {
  return Scaffold(
    appBar: AppBar(title: const Text('Recherche')),
    body: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Vue de recherche à implémenter',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    ),
  );
}
