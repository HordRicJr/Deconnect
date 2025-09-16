import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration des variables d'environnement pour Deconnect
class EnvConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get supabaseServiceRoleKey =>
      dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';
  static String get databaseUrl => dotenv.env['DATABASE_URL'] ?? '';
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
  static bool get isDebug => dotenv.env['DEBUG']?.toLowerCase() == 'true';

  /// Initialise les variables d'environnement
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
  }

  /// Vérifie si toutes les variables critiques sont configurées
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        supabaseServiceRoleKey.isNotEmpty;
  }

  /// Affiche les variables (sans les clés sensibles) pour debug
  static void debugPrint() {
    if (isDebug) {
      print('=== DECONNECT CONFIG ===');
      print('Environment: $environment');
      print(
        'Supabase URL: ${supabaseUrl.isNotEmpty ? "✅ Configured" : "❌ Missing"}',
      );
      print(
        'Anon Key: ${supabaseAnonKey.isNotEmpty ? "✅ Configured" : "❌ Missing"}',
      );
      print(
        'Service Key: ${supabaseServiceRoleKey.isNotEmpty ? "✅ Configured" : "❌ Missing"}',
      );
      print('========================');
    }
  }
}
