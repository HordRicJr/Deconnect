// Constantes de validation
class ValidationConstants {
  // Regex patterns
  static const String emailPattern =
      r'^[a-zA-Z0-9.!#$%&\047*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$';

  static const String usernamePattern = r'^[a-zA-Z0-9_]{3,30}$';

  static const String phonePattern = r'^\+?[\d\s\-\(\)]{10,}$';

  // Messages d'erreur
  static const String requiredFieldError = 'Ce champ est obligatoire';
  static const String invalidEmailError = 'Adresse email invalide';
  static const String passwordTooShortError =
      'Le mot de passe doit contenir au moins 8 caractères';
  static const String passwordMismatchError =
      'Les mots de passe ne correspondent pas';
  static const String invalidUsernameError =
      'Nom d\'utilisateur invalide (3-30 caractères, lettres, chiffres et _ autorisés)';
  static const String invalidPhoneError = 'Numéro de téléphone invalide';
  static const String fileTooLargeError = 'Le fichier est trop volumineux';
  static const String invalidFileTypeError = 'Type de fichier non autorisé';

  // Longueurs
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;
  static const int maxBioLength = 500;
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 2000;
}
