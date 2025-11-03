import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;

class LocationServiceDisabledException implements Exception {
  final String message;
  LocationServiceDisabledException([
    this.message = 'Le service de localisation est désactivé',
  ]);

  @override
  String toString() => message;
}

class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException([
    this.message = 'Permission de localisation refusée',
  ]);

  @override
  String toString() => message;
}

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
    // Vérifier si le service de localisation est activé
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    // Vérifier les permissions
    var permission = await checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw PermissionDeniedException();
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return latlong.LatLng(position.latitude, position.longitude);
    } on Exception catch (e) {
      debugPrint('Erreur lors de la récupération de la position: $e');
      rethrow;
    }
  }

  // Écoute les changements de statut du service de localisation
  Stream<ServiceStatus> getServiceStatusStream() {
    return Geolocator.getServiceStatusStream();
  }
}
