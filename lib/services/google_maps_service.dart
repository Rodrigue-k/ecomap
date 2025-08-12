import 'package:EcoMap/config/google_maps_config.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    as gmf; // Aliased for clarity
// It's good you're hiding LatLng and Circle from latlong2 to avoid conflicts.
// import 'package:latlong2/latlong.dart' hide LatLng, Circle; // Removed unused import, WasteBin uses its own LatLng
import '../models/waste_bin.dart';

class GoogleMapsService {
  static GoogleMapsService? _instance;
  // Singleton pattern is fine. If you use Riverpod extensively,
  // consider making this service a Riverpod provider for easier management.
  static GoogleMapsService get instance => _instance ??= GoogleMapsService._();

  GoogleMapsService._();

  // Configuration de la carte Google Maps
  gmf.CameraPosition getInitialCameraPosition(gmf.LatLng position) {
    return gmf.CameraPosition(
      target: position, // Assumes 'position' is already a gmf.LatLng
      zoom: GoogleMapsConfig.defaultZoom, // Corrected to use defaultZoom
    );
  }

  // Configuration des marqueurs de poubelles
  // Ajout d'un callback pour gérer le tap sur un marqueur
  Set<gmf.Marker> createWasteBinMarkers(
    List<WasteBin> wasteBins, {
    required Function(WasteBin bin) onMarkerTapped,
  }) {
    return wasteBins
        .map((bin) => _createWasteBinMarker(bin, onMarkerTapped))
        .toSet();
  }

  gmf.Marker _createWasteBinMarker(
    WasteBin bin,
    Function(WasteBin bin) onMarkerTapped,
  ) {
    return gmf.Marker(
      markerId: gmf.MarkerId(bin.id),
      position: gmf.LatLng(
        // Use gmf.LatLng for Google Maps
        bin.location.latitude, // Corrected: Access latitude from bin.location
        bin.location.longitude, // Corrected: Access longitude from bin.location
      ),
      infoWindow: gmf.InfoWindow(
        title: 'Poubelle ${bin.type ?? 'Non spécifiée'}',
        snippet: 'Statut: ${bin.status ?? 'Disponible'}',
      ),
      icon: _getMarkerIcon(bin.type ?? 'general'),
      onTap: () {
        onMarkerTapped(bin); // Appel du callback fourni
      },
    );
  }

  // Créer un marqueur pour la position actuelle
  gmf.Marker createCurrentLocationMarker(gmf.LatLng position) {
    return gmf.Marker(
      markerId: const gmf.MarkerId('current_location'),
      position: position,
      icon: gmf.BitmapDescriptor.defaultMarkerWithHue(
        gmf.BitmapDescriptor.hueBlue,
      ),
      infoWindow: const gmf.InfoWindow(
        title: 'Ma position',
        snippet: 'Votre position actuelle',
      ),
    );
  }

  // Obtenir l'icône appropriée selon le type de poubelle
  gmf.BitmapDescriptor _getMarkerIcon(String? binType) {
    // Gérer le cas où le type est null
    if (binType == null || binType.isEmpty) {
      return gmf.BitmapDescriptor.defaultMarkerWithHue(
        gmf.BitmapDescriptor.hueRed,
      );
    }
    
    // Pour améliorer la robustesse, envisagez d'utiliser un enum pour binType
    switch (binType.toLowerCase()) {
      case 'recyclable':
        return gmf.BitmapDescriptor.defaultMarkerWithHue(
          gmf.BitmapDescriptor.hueGreen,
        );
      case 'organic':
        return gmf.BitmapDescriptor.defaultMarkerWithHue(
          gmf.BitmapDescriptor.hueOrange,
        );
      case 'general':
      default:
        return gmf.BitmapDescriptor.defaultMarkerWithHue(
          gmf.BitmapDescriptor.hueRed,
        );
    }
  }

  // Configuration du cercle de rayon de recherche
  Set<gmf.Circle> createSearchRadiusCircle(
    gmf.LatLng center,
    double radiusInKm,
  ) {
    return {
      gmf.Circle(
        circleId: const gmf.CircleId('search_radius'),
        center: center,
        radius: radiusInKm * 1000, // Convertir en mètres
        fillColor: Colors.blue.withAlpha(
          (255 * 0.2).round(),
        ), // Corrected deprecated withOpacity
        strokeColor: Colors.blue,
        strokeWidth: 2,
      ),
    };
  }

  // Configuration des contrôles de la carte
  // Ajout de callbacks pour les boutons
  Set<Widget> createMapControls({
    required VoidCallback onMyLocationButtonPressed,
    required VoidCallback onMapTypeButtonPressed,
  }) {
    return {
      Positioned(
        right: 16,
        bottom: 100,
        child: FloatingActionButton(
          heroTag:
              'location_button', // Assurez-vous que les heroTags sont uniques
          onPressed: onMyLocationButtonPressed,
          backgroundColor:
              Colors.blue, // Envisagez d'utiliser Theme.of(context).colorScheme
          child: const Icon(Icons.my_location, color: Colors.white),
        ),
      ),
      Positioned(
        right: 16,
        bottom: 180,
        child: FloatingActionButton(
          heroTag: 'map_type_button',
          onPressed: onMapTypeButtonPressed,
          backgroundColor:
              Colors.grey, // Envisagez d'utiliser Theme.of(context).colorScheme
          child: const Icon(Icons.layers, color: Colors.white),
        ),
      ),
    };
  }

  // Concernant la méthode getMapOptions():
  // Le widget GoogleMap de google_maps_flutter prend ces options comme des paramètres nommés directs,
  // et non comme une unique Map d'options. Par exemple :
  //
  // GoogleMap(
  //   mapType: MapType.normal,
  //   compassEnabled: true,
  //   myLocationButtonEnabled: true, // Ceci est un bouton natif, distinct de votre FAB personnalisé
  //   myLocationEnabled: true,
  //   // ... autres options ...
  //   initialCameraPosition: ...,
  // )
  //
  // Cette méthode getMapOptions() n'est donc pas directement utilisable avec le widget GoogleMap.
  // Vous devriez appliquer ces valeurs directement lors de la création du widget GoogleMap.
  // Envisagez de supprimer cette méthode ou de clarifier son usage.
  Map<String, dynamic> getMapOptions() {
    // Cette structure n'est pas la manière dont google_maps_flutter consomme typiquement les options.
    return {
      'mapType': gmf.MapType.normal,
      'compassEnabled': true,
      'mapToolbarEnabled': true,
      'myLocationButtonEnabled': true,
      'myLocationEnabled': true,
      'zoomControlsEnabled':
          false, // La valeur par défaut peut varier selon la plateforme
      'liteModeEnabled': false, // Disponible uniquement sur Android
      'trafficEnabled': false,
      'rotateGesturesEnabled': true,
      'tiltGesturesEnabled': true,
      'zoomGesturesEnabled': true,
      'scrollGesturesEnabled': true,
    };
  }

  // Gestion des événements de la carte
  // Ces méthodes sont destinées à être passées en callback au widget GoogleMap.
  // L'implémentation de ce qui se passe dans ces callbacks sera dans la logique
  // de votre UI (par exemple, un ViewModel ou un StateNotifier si vous utilisez Riverpod).

  void onMapCreated(gmf.GoogleMapController controller) {
    // Gérer l'initialisation du contrôleur de la carte
    // Exemple: stocker le contrôleur pour une utilisation ultérieure
    // print('Map Created! Controller: $controller');
  }

  void onCameraMove(gmf.CameraPosition position) {
    // Gérer le mouvement de la caméra
    // Exemple: Mettre à jour un état basé sur la position de la caméra
    // print('Camera Moving: ${position.target}, Zoom: ${position.zoom}');
  }

  void onCameraIdle() {
    // Gérer l'arrêt du mouvement de la caméra
    // Exemple: Charger de nouvelles données pour la zone visible
    // print('Camera Idle');
  }

  void onTap(gmf.LatLng position) {
    // Gérer le tap sur la carte
    // print('Map Tapped at: $position');
  }

  void onLongPress(gmf.LatLng position) {
    // Gérer le long press sur la carte
    // print('Map Long Pressed at: $position');
  }
}
