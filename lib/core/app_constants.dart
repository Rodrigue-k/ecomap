class AppConstants {
  // Nom de l'application
  static const String appName = 'EcoMap';
  static const String appVersion = '1.0.0';
  
  // Position par défaut (Lomé, Togo)
  static const double defaultLatitude = 6.1375;
  static const double defaultLongitude = 1.2123;
  static const double defaultZoom = 15.0;
  
  // Rayon de recherche des poubelles (en km)
  static const double searchRadius = 5.0;
  
  // Limites de la carte
  static const double minZoom = 10.0;
  static const double maxZoom = 18.0;
  
  // Dimensions des marqueurs
  static const double markerSize = 40.0;
  static const double markerIconSize = 20.0;
  
  // Espacements
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  // Rayons de bordure
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 20.0;
  
  // Durées d'animation
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);
  
  // Messages
  static const String locationError = 'Erreur de localisation';
  static const String locationSuccess = 'Localisation réussie';
  static const String networkError = 'Erreur de réseau';
  static const String unknownError = 'Erreur inconnue';
  
  // Types de poubelles
  static const List<String> binTypes = [
    'general',
    'recyclable',
    'organic',
  ];
  
  // Statuts des poubelles
  static const List<String> binStatuses = [
    'available',
    'full',
    'maintenance',
  ];
}
