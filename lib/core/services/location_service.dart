import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import '../core/app_logger.dart';

class LocationService {
  static Future<LatLng?> getCurrentLocation({BuildContext? context}) async {
    AppLogger.i('LocationService.getCurrentLocation() called');
    bool serviceEnabled;
    LocationPermission permission;

    // Vérifier si les services de localisation sont activés
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    AppLogger.d('Location service enabled: $serviceEnabled');
    if (!serviceEnabled) {
      if (context != null) {
        _showLocationServiceDialog(context);
      }
      AppLogger.w('Location services are disabled');
      return null;
    }

    // Vérifier les permissions
    permission = await Geolocator.checkPermission();
    AppLogger.d('Initial location permission: $permission');
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      AppLogger.d('Requested permission, result: $permission');
      if (permission == LocationPermission.denied) {
        if (context != null) {
          _showPermissionDeniedDialog(context);
        }
        AppLogger.w('Permission denied after request');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context != null) {
        _showPermissionPermanentlyDeniedDialog(context);
      }
      AppLogger.w('Permission permanently denied');
      return null;
    }

    try {
      // Obtenir la position avec une précision élevée
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      );
      AppLogger.d(
        'Current position: (${position.latitude}, ${position.longitude}), accuracy: ${position.accuracy}',
      );

      // Vérifier la précision de la position
      if (position.accuracy > 20) {
        // Si la précision est supérieure à 20 mètres
        // Essayer d'obtenir une position plus précise
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        AppLogger.d(
          'Refined position: (${position.latitude}, ${position.longitude}), accuracy: ${position.accuracy}',
        );
      }

      return LatLng(position.latitude, position.longitude);
    } catch (e, st) {
      AppLogger.e('Error in getCurrentLocation', e, st);
      if (context != null) {
        _showLocationErrorDialog(context, e.toString());
      }
      return null;
    }
  }

  static Future<LatLng?> getLastKnownLocation() async {
    try {
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        AppLogger.d(
          'Last known position: (${position.latitude}, ${position.longitude}), accuracy: ${position.accuracy}',
        );
        return LatLng(position.latitude, position.longitude);
      }
      return null;
    } catch (e, st) {
      AppLogger.e('Error in getLastKnownLocation', e, st);
      return null;
    }
  }

  static Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<LocationPermission> getLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  static double? getDistance(LatLng from, LatLng to) {
    try {
      double distanceInMeters = Geolocator.distanceBetween(
        from.latitude,
        from.longitude,
        to.latitude,
        to.longitude,
      );
      return distanceInMeters;
    } catch (e) {
      return null;
    }
  }

  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      double distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }

  // Dialogues pour informer l'utilisateur
  static void _showLocationServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Services de localisation désactivés'),
          content: const Text(
            'Veuillez activer les services de localisation dans les paramètres de votre appareil pour utiliser cette fonctionnalité.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
              child: const Text('Paramètres'),
            ),
          ],
        );
      },
    );
  }

  static void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission de localisation refusée'),
          content: const Text(
            'Cette application a besoin de votre permission pour accéder à votre position afin de vous montrer les poubelles à proximité.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.requestPermission();
              },
              child: const Text('Autoriser'),
            ),
          ],
        );
      },
    );
  }

  static void _showPermissionPermanentlyDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Permission de localisation refusée définitivement',
          ),
          content: const Text(
            'Vous avez refusé définitivement l\'accès à la localisation. Veuillez l\'activer manuellement dans les paramètres de l\'application.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
              child: const Text('Paramètres'),
            ),
          ],
        );
      },
    );
  }

  static void _showLocationErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Erreur de localisation'),
          content: Text(
            'Impossible d\'obtenir votre position actuelle. Erreur: $error',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
