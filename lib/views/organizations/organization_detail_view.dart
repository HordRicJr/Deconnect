import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrganizationDetailView extends ConsumerStatefulWidget {
  final String organizationId;

  const OrganizationDetailView({super.key, required this.organizationId});

  @override
  ConsumerState<OrganizationDetailView> createState() =>
      _OrganizationDetailViewState();
}

class _OrganizationDetailViewState
    extends ConsumerState<OrganizationDetailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail de l\'organisation')),
      body: const Center(
        child: Text(
          'Vue détail organisation en cours de développement',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
