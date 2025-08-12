// lib/config/google_maps_config.dart

class GoogleMapsConfig {
  // Activer le mode Lite pour des performances accrues sur les appareils bas de gamme
  // ou lorsque moins de fonctionnalités de carte sont nécessaires.
  // Le mode Lite désactive certaines fonctionnalités interactives comme les gestes,
  // l'inclinaison, la rotation, les bâtiments 3D, etc.
  static const bool liteModeEnabled =
      false; // Modifié pour désactiver le mode Lite

  // Niveau de zoom initial pour la caméra de la carte
  static const double defaultZoom = 14.0;

  // Style de carte personnalisé (facultatif)
  // Vous pouvez générer un style JSON à partir de https://mapstyle.withgoogle.com/
  // static const String? customMapStyleJson = null; // Exemple : '''[...]''';

  // Activer/désactiver la barre d'outils de la carte (accès à Google Maps et directions)
  static const bool mapToolbarEnabled = true;

  // Activer/désactiver la boussole sur la carte
  static const bool compassEnabled = true;

  // Activer/désactiver les contrôles de zoom
  static const bool zoomControlsEnabled = true;

  // Activer/désactiver le bouton "Ma position"
  // Note: myLocationLayerEnabled doit également être vrai pour que cela fonctionne.
  static const bool myLocationButtonEnabled = true;
}
