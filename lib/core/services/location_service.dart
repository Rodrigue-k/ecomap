import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Vérifie si le service de localisation est activé
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Vérifie les permissions de localisation actuelles
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Demande les permissions de localisation
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Obtient la position actuelle de l'utilisateur
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      throw PermissionDeniedException();
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Ouvre les paramètres de localisation de l'appareil
  Future<bool> openLocationSettings() async {
    if (await Geolocator.isLocationServiceEnabled()) {
      return false;
    }

    return Geolocator.openLocationSettings();
  }

  /// Ouvre les paramètres de l'application
  Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }
}

class LocationServiceDisabledException implements Exception {
  @override
  String toString() => 'Le service de localisation est désactivé';
}

class PermissionDeniedException implements Exception {
  @override
  String toString() => 'L\'accès à la localisation a été refusé';
}
