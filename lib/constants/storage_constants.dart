// Constantes de stockage
class StorageConstants {
  // Buckets Supabase Storage
  static const String avatarsBucket = 'avatars';
  static const String eventImagesBucket = 'event-images';
  static const String organizationImagesBucket = 'organization-images';
  static const String challengeImagesBucket = 'challenge-images';
  static const String documentsBucket = 'documents';

  // Dossiers locaux
  static const String avatarsFolder = 'avatars';
  static const String cacheFolder = 'cache';
  static const String tempFolder = 'temp';
  static const String documentsFolder = 'documents';

  // Tailles de fichiers (en bytes)
  static const int maxAvatarSize = 5 * 1024 * 1024; // 5MB
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const int maxDocumentSize = 50 * 1024 * 1024; // 50MB

  // Types de fichiers autorisés
  static const List<String> imageTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  static const List<String> documentTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain',
  ];

  // Durée de vie des caches
  static const Duration cacheExpiration = Duration(hours: 24);
  static const Duration tempFileExpiration = Duration(hours: 1);

  // Clés de cache
  static const String profileCacheKey = 'profile_cache';
  static const String challengesCacheKey = 'challenges_cache';
  static const String eventsCacheKey = 'events_cache';
}
