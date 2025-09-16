import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventDetailView extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailView({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends ConsumerState<EventDetailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail de l\'événement')),
      body: const Center(
        child: Text(
          'Vue détail événement en cours de développement',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
