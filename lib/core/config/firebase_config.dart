class FirebaseConfig {
  // Configuration Firebase
  static const String projectId = 'ecomap-ac716';

  // Collections Firestore
  static const String wasteBinsCollection = 'waste_bins';
  static const String usersCollection = 'users';

  // Configuration des règles de sécurité recommandées
  static const Map<String, dynamic> securityRules = {
    'waste_bins': {
      'read': 'auth != null || true', // Lecture publique
      'write': 'auth != null', // Écriture authentifiée
      'create': 'auth != null && request.resource.data.createdBy == auth.uid',
      'update': 'auth != null && resource.data.createdBy == auth.uid',
      'delete': 'auth != null && resource.data.createdBy == auth.uid',
    },
    'users': {
      'read': 'auth != null && auth.uid == resource.id',
      'write': 'auth != null && auth.uid == resource.id',
    },
  };

  // Messages d'erreur personnalisés
  static const Map<String, String> errorMessages = {
    'permission_denied':
        'Vous n\'avez pas les permissions nécessaires pour cette action.',
    'not_found': 'La ressource demandée n\'a pas été trouvée.',
    'already_exists': 'Cette ressource existe déjà.',
    'resource_exhausted':
        'Limite de requêtes atteinte. Veuillez réessayer plus tard.',
    'unavailable': 'Service temporairement indisponible. Veuillez réessayer.',
  };
}
