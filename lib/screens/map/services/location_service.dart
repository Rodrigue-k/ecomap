import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;

class LocationService {
  // Vérifie si le service de localisation est activé
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Demande la permission de localisation
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  // Vérifie la permission actuelle
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  // Ouvre les paramètres de localisation
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  // Ouvre les paramètres de l'application
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // Récupère la position actuelle
  Future<latlong.LatLng> getCurrentPosition() async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return latlong.LatLng(position.latitude, position.longitude);
  }

  // Écoute les changements de statut du service de localisation
  Stream<ServiceStatus> getServiceStatusStream() {
    return Geolocator.getServiceStatusStream();
  }
}
