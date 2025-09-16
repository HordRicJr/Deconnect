# Deconnect - Architecture Documentation

## Structure du Projet

L'application Deconnect suit une architecture MVC (Model-View-Controller) avec Riverpod pour la gestion d'état.

### 📁 Structure des Dossiers

```
lib/
├── main.dart                    # Point d'entrée de l'application
├── config/                     # Configuration de l'application
├── models/                     # Modèles de données
├── controllers/                # Contrôleurs (logique métier)
├── views/                      # Vues (interface utilisateur)
├── widgets/                    # Widgets réutilisables
├── services/                   # Services (API, base de données)
├── providers/                  # Providers Riverpod
├── router/                     # Configuration du routage
└── constants/                  # Constantes de l'application
```

### 🏗️ Architecture MVC avec Riverpod

#### Models (Modèles)
- `User` : Modèle utilisateur avec profil et préférences
- `Challenge` : Défis de déconnexion avec règles et participants
- `FocusSession` : Sessions de concentration avec minuteur
- `Event` : Événements et activités sociales
- `Organization` : Organisations et communautés

#### Views (Vues)
- **Dashboard** : Tableau de bord principal avec statistiques
- **Profile** : Profil utilisateur et gestion des données
- **Challenges** : Découverte et participation aux défis
- **Events** : Événements et sessions de focus
- **Settings** : Paramètres et préférences

#### Controllers (Contrôleurs)
- **AuthController** : Authentification et gestion des sessions
- **DashboardController** : Logique du tableau de bord
- **ProfileController** : Gestion du profil utilisateur
- **ChallengesController** : Logique des défis
- **EventsController** : Gestion des événements

#### Services
- **AppService** : Service principal de l'application
- **AuthService** : Service d'authentification
- **DatabaseService** : Service de base de données
- **NotificationService** : Service de notifications

### 🔗 Navigation

L'application utilise un système de navigation par onglets avec `MainNavigationView` :

1. **Dashboard** - Tableau de bord et statistiques
2. **Challenges** - Défis et communauté
3. **Focus** - Sessions de concentration
4. **Events** - Événements et activités
5. **Profile** - Profil et paramètres

### 🎨 Composants UI

#### Widgets Communs
- `ErrorWidget` : Affichage d'erreurs avec actions
- `StatsCard` : Cartes de statistiques
- `ActivityTile` : Tuiles d'activité

#### Widgets Spécialisés
- **Challenges** : Cartes de défis, création, découverte
- **Events** : Création et liste d'événements
- **Profile** : Badges, graphiques, streaks

### 🔄 Gestion d'État

L'application utilise Riverpod pour la gestion d'état :

- **StateNotifier** pour les états complexes avec logique métier
- **Provider** pour les services et dépendances
- **FutureProvider** pour les données asynchrones
- **StreamProvider** pour les flux de données en temps réel

### 🚀 Démarrage

```bash
# Installation des dépendances
flutter pub get

# Configuration de l'environnement
cp .env.example .env
# Configurer les variables d'environnement

# Lancement de l'application
flutter run
```

### 📱 Fonctionnalités Principales

1. **Authentification** : Connexion sécurisée avec Supabase
2. **Tableau de Bord** : Statistiques d'utilisation et progrès
3. **Défis** : Création et participation à des défis de déconnexion
4. **Sessions Focus** : Minuteur de concentration avec paramètres
5. **Événements** : Organisation d'activités sociales
6. **Profil** : Gestion des données personnelles et préférences
7. **Paramètres** : Configuration de l'application

### 🔧 Technologies Utilisées

- **Flutter** : Framework UI multiplateforme
- **Riverpod** : Gestion d'état reactive
- **Supabase** : Backend-as-a-Service
- **Material Design 3** : Système de design moderne
- **go_router** : Navigation déclarative

### 📋 Prochaines Étapes

1. Implémentation des services backend
2. Tests unitaires et d'intégration
3. Optimisation des performances
4. Publication sur les stores