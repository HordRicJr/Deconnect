import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/focus_session_controller.dart';

class FocusView extends ConsumerWidget {
  const FocusView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusState = ref.watch(focusSessionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Focus Sessions')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology, size: 80, color: Colors.blue),
            SizedBox(height: 20),
            Text(
              'Sessions de Focus',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Gérez vos sessions de concentration ici',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create session
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
