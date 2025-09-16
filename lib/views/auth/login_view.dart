import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginView extends ConsumerWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo et titre
              Column(
                children: [
                  Icon(
                    Icons.phone_android_outlined,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Deconnect',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reconnectez-vous au monde réel',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Boutons de connexion (version simplifiée pour démo)
              ElevatedButton.icon(
                onPressed: () {
                  // Pour la démo, on simule une connexion réussie
                  // En réalité, cela passerait par les controllers d'auth
                },
                icon: const Icon(Icons.login),
                label: const Text('Se connecter avec email'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () {
                  // Navigation vers l'inscription
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Créer un compte'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 32),

              // Connexion rapide pour démo
              TextButton(
                onPressed: () {
                  // Mode démo - connexion directe
                  Navigator.of(context).pushReplacementNamed('/main');
                },
                child: const Text('Mode démo (connexion rapide)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
