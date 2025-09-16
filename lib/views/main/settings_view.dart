import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/profile_controller.dart';
import '../../controllers/auth_controller.dart';
import '../widgets/widgets.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          // Section Profil
          const ListTile(
            title: Text(
              'Profil',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          ListTile(
            leading: CircleAvatar(
              backgroundImage: profileState.profile?.avatarUrl != null
                  ? NetworkImage(profileState.profile!.avatarUrl!)
                  : null,
              child: profileState.profile?.avatarUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(
              profileState.profile?.displayName ?? 'Nom d\'utilisateur',
            ),
            subtitle: Text(authState.user?.email ?? ''),
            trailing: const Icon(Icons.edit),
            onTap: _editProfile,
          ),

          const Divider(),

          // Section Notifications
          const ListTile(
            title: Text(
              'Notifications',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          SwitchListTile(
            title: const Text('Notifications de focus'),
            subtitle: const Text('Recevoir des rappels pour vos sessions'),
            value: profileState.profile?.focusNotifications ?? true,
            onChanged: _toggleFocusNotifications,
            secondary: const Icon(Icons.notifications),
          ),

          SwitchListTile(
            title: const Text('Notifications d\'événements'),
            subtitle: const Text('Être notifié des nouveaux événements'),
            value: profileState.profile?.eventNotifications ?? true,
            onChanged: _toggleEventNotifications,
            secondary: const Icon(Icons.event),
          ),

          const Divider(),

          // Section Focus
          const ListTile(
            title: Text(
              'Sessions Focus',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Durée par défaut'),
            subtitle: Text(
              '${profileState.profile?.defaultFocusDuration ?? 25} minutes',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _setDefaultDuration,
          ),

          SwitchListTile(
            title: const Text('Son de fin de session'),
            subtitle: const Text('Jouer un son à la fin d\'une session'),
            value: profileState.profile?.soundEnabled ?? true,
            onChanged: _toggleSound,
            secondary: const Icon(Icons.volume_up),
          ),

          const Divider(),

          // Section Confidentialité
          const ListTile(
            title: Text(
              'Confidentialité',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          SwitchListTile(
            title: const Text('Profil public'),
            subtitle: const Text('Permettre aux autres de voir votre profil'),
            value: profileState.profile?.isPublic ?? false,
            onChanged: _togglePublicProfile,
            secondary: const Icon(Icons.public),
          ),

          SwitchListTile(
            title: const Text('Statistiques visibles'),
            subtitle: const Text('Montrer vos statistiques sur votre profil'),
            value: profileState.profile?.showStats ?? true,
            onChanged: _toggleShowStats,
            secondary: const Icon(Icons.analytics),
          ),

          const Divider(),

          // Section À propos
          const ListTile(
            title: Text(
              'À propos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Aide et support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showHelp,
          ),

          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('À propos de l\'app'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showAbout,
          ),

          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Politique de confidentialité'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showPrivacyPolicy,
          ),

          const Divider(),

          // Section Compte
          const ListTile(
            title: Text(
              'Compte',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.red),
            ),
            onTap: _signOut,
          ),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Supprimer le compte',
              style: TextStyle(color: Colors.red),
            ),
            onTap: _deleteAccount,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _editProfile() {
    // Navigation vers l'édition du profil
  }

  void _toggleFocusNotifications(bool value) {
    ref
        .read(profileControllerProvider.notifier)
        .updateNotificationSettings(focusNotifications: value);
  }

  void _toggleEventNotifications(bool value) {
    ref
        .read(profileControllerProvider.notifier)
        .updateNotificationSettings(eventNotifications: value);
  }

  void _setDefaultDuration() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Durée par défaut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choisissez la durée par défaut pour vos sessions focus :',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [15, 20, 25, 30, 45, 60].map((duration) {
                return ChoiceChip(
                  label: Text('$duration min'),
                  selected: false,
                  onSelected: (selected) {
                    if (selected) {
                      ref
                          .read(profileControllerProvider.notifier)
                          .updateDefaultFocusDuration(duration);
                      Navigator.of(context).pop();
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _toggleSound(bool value) {
    ref
        .read(profileControllerProvider.notifier)
        .updateSettings(soundEnabled: value);
  }

  void _togglePublicProfile(bool value) {
    ref
        .read(profileControllerProvider.notifier)
        .updatePrivacySettings(isPublic: value);
  }

  void _toggleShowStats(bool value) {
    ref
        .read(profileControllerProvider.notifier)
        .updatePrivacySettings(showStats: value);
  }

  void _showHelp() {
    // Navigation vers l'aide
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Déconnect',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.phone_android),
      children: const [
        Text(
          'Application pour améliorer votre bien-être numérique et vous reconnecter à la vie réelle.',
        ),
      ],
    );
  }

  void _showPrivacyPolicy() {
    // Navigation vers la politique de confidentialité
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authControllerProvider.notifier).signOut();
            },
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront définitivement supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implémenter la suppression du compte
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
