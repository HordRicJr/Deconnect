import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_service.dart';
import '../../constants/storage_constants.dart';

// Types de stockage
enum StorageType { local, cloud, cache }

// Options d'upload
class UploadOptions {
  final String? contentType;
  final bool overwrite;
  final Map<String, String>? metadata;
  final void Function(double)? onProgress;

  const UploadOptions({
    this.contentType,
    this.overwrite = false,
    this.metadata,
    this.onProgress,
  });
}

// Résultat d'upload
class UploadResult {
  final String path;
  final String? publicUrl;
  final int size;
  final String? contentType;
  final Map<String, String>? metadata;

  const UploadResult({
    required this.path,
    this.publicUrl,
    required this.size,
    this.contentType,
    this.metadata,
  });
}

// Exception de stockage
class StorageException implements Exception {
  final String message;
  final String? code;

  const StorageException(this.message, {this.code});

  @override
  String toString() =>
      'StorageException: $message${code != null ? ' (code: $code)' : ''}';
}

// Service de stockage unifié
class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();

  StorageService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService.instance;

  // Stockage local (fichiers)
  Future<File> saveToLocal(
    String fileName,
    Uint8List data, {
    String? subdirectory,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = subdirectory != null
          ? '${directory.path}/$subdirectory'
          : directory.path;

      // Créer le dossier si nécessaire
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final file = File('$path/$fileName');
      return await file.writeAsBytes(data);
    } catch (e) {
      throw StorageException('Erreur lors de l\'écriture locale: $e');
    }
  }

  Future<Uint8List?> loadFromLocal(
    String fileName, {
    String? subdirectory,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = subdirectory != null
          ? '${directory.path}/$subdirectory/$fileName'
          : '${directory.path}/$fileName';

      final file = File(path);
      if (!await file.exists()) {
        return null;
      }

      return await file.readAsBytes();
    } catch (e) {
      throw StorageException('Erreur lors de la lecture locale: $e');
    }
  }

  Future<bool> deleteFromLocal(String fileName, {String? subdirectory}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = subdirectory != null
          ? '${directory.path}/$subdirectory/$fileName'
          : '${directory.path}/$fileName';

      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      throw StorageException('Erreur lors de la suppression locale: $e');
    }
  }

  // Stockage cloud (Supabase Storage)
  Future<UploadResult> uploadToCloud(
    String bucket,
    String fileName,
    Uint8List data, {
    UploadOptions? options,
  }) async {
    try {
      if (!_authService.isAuthenticated) {
        throw const StorageException('Utilisateur non authentifié');
      }

      final userId = _authService.currentUser!.id;
      final fullPath = '$userId/$fileName';

      final fileOptions = FileOptions(
        contentType: options?.contentType,
        upsert: options?.overwrite ?? false,
      );

      await _supabase.storage
          .from(bucket)
          .uploadBinary(fullPath, data, fileOptions: fileOptions);

      // Obtenir l'URL publique si possible
      String? publicUrl;
      try {
        publicUrl = _supabase.storage.from(bucket).getPublicUrl(fullPath);
      } catch (e) {
        // Bucket privé, pas d'URL publique
      }

      return UploadResult(
        path: fullPath,
        publicUrl: publicUrl,
        size: data.length,
        contentType: options?.contentType,
        metadata: options?.metadata,
      );
    } catch (e) {
      throw StorageException('Erreur lors de l\'upload cloud: $e');
    }
  }

  Future<UploadResult> uploadFileToCloud(
    String bucket,
    File file, {
    String? fileName,
    UploadOptions? options,
  }) async {
    try {
      final data = await file.readAsBytes();
      final name = fileName ?? file.path.split('/').last;

      return await uploadToCloud(bucket, name, data, options: options);
    } catch (e) {
      throw StorageException('Erreur lors de l\'upload fichier: $e');
    }
  }

  Future<Uint8List> downloadFromCloud(String bucket, String path) async {
    try {
      final data = await _supabase.storage.from(bucket).download(path);
      return data;
    } catch (e) {
      throw StorageException('Erreur lors du téléchargement cloud: $e');
    }
  }

  Future<bool> deleteFromCloud(String bucket, String path) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
      return true;
    } catch (e) {
      throw StorageException('Erreur lors de la suppression cloud: $e');
    }
  }

  String getPublicUrl(String bucket, String path) {
    try {
      return _supabase.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      throw StorageException('Erreur lors de la génération URL: $e');
    }
  }

  Future<String> createSignedUrl(
    String bucket,
    String path, {
    Duration expiration = const Duration(hours: 1),
  }) async {
    try {
      final url = await _supabase.storage
          .from(bucket)
          .createSignedUrl(path, expiration.inSeconds);
      return url;
    } catch (e) {
      throw StorageException('Erreur lors de la génération URL signée: $e');
    }
  }

  // Stockage cache (SharedPreferences)
  Future<void> saveToCache(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      throw StorageException('Erreur lors de la mise en cache: $e');
    }
  }

  Future<String?> loadFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      throw StorageException('Erreur lors de la lecture cache: $e');
    }
  }

  Future<bool> deleteFromCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(key);
    } catch (e) {
      throw StorageException('Erreur lors de la suppression cache: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw StorageException('Erreur lors de la suppression cache: $e');
    }
  }

  // Méthodes spécialisées pour les avatars
  Future<UploadResult> uploadAvatar(File file) async {
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await uploadFileToCloud(
      StorageConstants.avatarsBucket,
      file,
      fileName: fileName,
      options: const UploadOptions(contentType: 'image/jpeg', overwrite: true),
    );
  }

  Future<String> getAvatarUrl(String path) async {
    try {
      return await createSignedUrl(StorageConstants.avatarsBucket, path);
    } catch (e) {
      return getPublicUrl(StorageConstants.avatarsBucket, path);
    }
  }

  // Méthodes pour les fichiers d'événements
  Future<UploadResult> uploadEventImage(File file, String eventId) async {
    final extension = file.path.split('.').last;
    final fileName =
        'event_${eventId}_${DateTime.now().millisecondsSinceEpoch}.$extension';

    return await uploadFileToCloud(
      StorageConstants.eventImagesBucket,
      file,
      fileName: fileName,
      options: const UploadOptions(overwrite: true),
    );
  }

  // Gestion des fichiers temporaires
  Future<Directory> getTemporaryDirectory() async {
    return await getTemporaryDirectory();
  }

  Future<File> createTempFile(String fileName, Uint8List data) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      return await file.writeAsBytes(data);
    } catch (e) {
      throw StorageException(
        'Erreur lors de la création fichier temporaire: $e',
      );
    }
  }

  // Utilitaires
  Future<int> getLocalStorageSize({String? subdirectory}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = subdirectory != null
          ? '${directory.path}/$subdirectory'
          : directory.path;

      final dir = Directory(path);
      if (!await dir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }

      return totalSize;
    } catch (e) {
      throw StorageException('Erreur lors du calcul de taille: $e');
    }
  }

  Future<void> cleanupOldFiles({
    String? subdirectory,
    Duration maxAge = const Duration(days: 30),
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = subdirectory != null
          ? '${directory.path}/$subdirectory'
          : directory.path;

      final dir = Directory(path);
      if (!await dir.exists()) {
        return;
      }

      final cutoffTime = DateTime.now().subtract(maxAge);

      await for (final entity in dir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffTime)) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      throw StorageException('Erreur lors du nettoyage: $e');
    }
  }

  // Synchronisation entre local et cloud
  Future<bool> syncFileToCloud(
    String localFileName,
    String bucket,
    String cloudPath, {
    String? subdirectory,
    UploadOptions? options,
  }) async {
    try {
      final data = await loadFromLocal(
        localFileName,
        subdirectory: subdirectory,
      );
      if (data == null) {
        return false;
      }

      await uploadToCloud(bucket, cloudPath, data, options: options);
      return true;
    } catch (e) {
      throw StorageException('Erreur lors de la synchronisation: $e');
    }
  }

  Future<bool> syncFileFromCloud(
    String bucket,
    String cloudPath,
    String localFileName, {
    String? subdirectory,
  }) async {
    try {
      final data = await downloadFromCloud(bucket, cloudPath);
      await saveToLocal(localFileName, data, subdirectory: subdirectory);
      return true;
    } catch (e) {
      throw StorageException('Erreur lors de la synchronisation: $e');
    }
  }
}
