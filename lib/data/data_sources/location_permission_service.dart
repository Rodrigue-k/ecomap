import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/app_logger.dart';

class LocationPermissionService {
  /// Vérifie et demande les permissions de localisation nécessaires
  static Future<bool> requestLocationPermissionForAddingBin(
    BuildContext context,
  ) async {
    AppLogger.i(
      'LocationPermissionService: Vérification des permissions de localisation',
    );

    // Vérifier d'abord si les services de localisation sont activés
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    AppLogger.d(
      'LocationPermissionService: Services de localisation activés: $serviceEnabled',
    );

    if (!serviceEnabled) {
      AppLogger.w(
        'LocationPermissionService: Services de localisation désactivés',
      );
      if (context.mounted) {
        await _showLocationServiceDialog(context);
      }
      return false;
    }

    // Vérifier les permissions
    LocationPermission permission = await Geolocator.checkPermission();
    AppLogger.d('LocationPermissionService: Permission actuelle: $permission');

    if (permission == LocationPermission.denied) {
      // Demander la permission
      AppLogger.i('LocationPermissionService: Demande de permission...');
      permission = await Geolocator.requestPermission();
      AppLogger.d(
        'LocationPermissionService: Permission après demande: $permission',
      );

      if (permission == LocationPermission.denied) {
        AppLogger.w('LocationPermissionService: Permission refusée');
        if (context.mounted) {
          await _showPermissionDeniedDialog(context);
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      AppLogger.w(
        'LocationPermissionService: Permission refusée définitivement',
      );
      if (context.mounted) {
        await _showPermissionPermanentlyDeniedDialog(context);
      }
      return false;
    }

    // Vérifier la permission avec permission_handler pour plus de contrôle
    PermissionStatus status = await Permission.location.status;
    AppLogger.d(
      'LocationPermissionService: Status permission_handler: $status',
    );

    if (status.isDenied) {
      AppLogger.i(
        'LocationPermissionService: Demande de permission via permission_handler...',
      );
      status = await Permission.location.request();
      AppLogger.d('LocationPermissionService: Status après demande: $status');

      if (status.isDenied) {
        AppLogger.w(
          'LocationPermissionService: Permission refusée via permission_handler',
        );
        if (context.mounted) {
          await _showPermissionDeniedDialog(context);
        }
        return false;
      }
    }

    if (status.isPermanentlyDenied) {
      AppLogger.w(
        'LocationPermissionService: Permission refusée définitivement via permission_handler',
      );
      if (context.mounted) {
        await _showPermissionPermanentlyDeniedDialog(context);
      }
      return false;
    }

    AppLogger.i('LocationPermissionService: Toutes les permissions accordées');
    return true;
  }

  /// Vérifie si la localisation est suffisamment précise pour ajouter une poubelle
  static Future<bool> isLocationAccurateEnough(BuildContext context) async {
    AppLogger.i(
      'LocationPermissionService: Vérification de la précision de localisation',
    );

    try {
      // Obtenir la position avec une précision élevée
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 30),
      );
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      AppLogger.d(
        'LocationPermissionService: Position obtenue - Précision: ${position.accuracy}m, Altitude: ${position.altitude}m, Vitesse: ${position.speed}m/s',
      );

      // Vérifier la précision (en mètres) - plus permissif pour les tests
      if (position.accuracy > 20) {
        // Augmenté à 20 mètres pour les tests
        AppLogger.w(
          'LocationPermissionService: Précision insuffisante: ${position.accuracy}m',
        );
        if (context.mounted) {
          await _showLowAccuracyDialog(context, position.accuracy);
        }
        return false;
      }

      AppLogger.i(
        'LocationPermissionService: Précision suffisante: ${position.accuracy}m',
      );
      return true;
    } catch (e, stackTrace) {
      AppLogger.e(
        'LocationPermissionService: Erreur lors de la vérification de précision',
        e,
        stackTrace,
      );
      if (context.mounted) {
        await _showLocationErrorDialog(context, e.toString());
      }
      return false;
    }
  }

  /// Obtient la position actuelle avec vérification de précision améliorée
  static Future<Position?> getAccurateLocation(BuildContext context) async {
    AppLogger.i('LocationPermissionService: Obtention de la position précise');

    try {
      // Première tentative avec la meilleure précision
      AppLogger.d(
        'LocationPermissionService: Première tentative avec LocationAccuracy.best',
      );
      LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 30),
      );
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      AppLogger.d(
        'LocationPermissionService: Première position - Précision: ${position.accuracy}m',
      );

      // Si la précision n'est pas suffisante, essayer d'améliorer
      if (position.accuracy > 20) {
        AppLogger.i(
          'LocationPermissionService: Précision insuffisante, tentative d\'amélioration...',
        );

        // Attendre un peu et essayer à nouveau
        await Future.delayed(const Duration(seconds: 3));

        AppLogger.d(
          'LocationPermissionService: Deuxième tentative avec LocationAccuracy.high',
        );
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        );
        position = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        );

        AppLogger.d(
          'LocationPermissionService: Deuxième position - Précision: ${position.accuracy}m',
        );

        // Si toujours pas assez précis, essayer une dernière fois
        if (position.accuracy > 20) {
          AppLogger.i(
            'LocationPermissionService: Précision toujours insuffisante, dernière tentative...',
          );
          await Future.delayed(const Duration(seconds: 2));

          locationSettings = const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 15),
          );
          position = await Geolocator.getCurrentPosition(
            locationSettings: locationSettings,
          );

          AppLogger.d(
            'LocationPermissionService: Position finale - Précision: ${position.accuracy}m',
          );
        }
      }

      // Vérifier si on a une position utilisable
      if (position.accuracy <= 50) {
        // Accepte jusqu'à 50m pour les tests
        AppLogger.i(
          'LocationPermissionService: Position obtenue avec succès - Précision: ${position.accuracy}m',
        );
        return position;
      } else {
        AppLogger.w(
          'LocationPermissionService: Précision finale insuffisante: ${position.accuracy}m',
        );
        if (context.mounted) {
          await _showLowAccuracyDialog(context, position.accuracy);
        }
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'LocationPermissionService: Erreur lors de l\'obtention de la position',
        e,
        stackTrace,
      );
      if (context.mounted) {
        await _showLocationErrorDialog(context, e.toString());
      }
      return null;
    }
  }

  /// Obtient la position avec plusieurs tentatives et affichage du progrès
  static Future<Position?> getLocationWithProgress(
    BuildContext context,
    Function(String) onProgressUpdate,
  ) async {
    AppLogger.i(
      'LocationPermissionService: Obtention de position avec progrès',
    );

    try {
      onProgressUpdate('Initialisation de la localisation...');
      await Future.delayed(const Duration(milliseconds: 500));

      onProgressUpdate('Recherche du signal GPS...');
      await Future.delayed(const Duration(milliseconds: 1000));

      onProgressUpdate('Obtention de la position précise...');

      final position = await getAccurateLocation(context);

      if (position != null) {
        onProgressUpdate(
          'Position obtenue avec une précision de ${position.accuracy.toStringAsFixed(1)}m',
        );
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      return position;
    } catch (e, stackTrace) {
      AppLogger.e(
        'LocationPermissionService: Erreur dans getLocationWithProgress',
        e,
        stackTrace,
      );
      onProgressUpdate('Erreur lors de l\'obtention de la position');
      return null;
    }
  }

  /// Ouvre les paramètres de localisation
  static Future<void> openLocationSettings() async {
    AppLogger.i(
      'LocationPermissionService: Ouverture des paramètres de localisation',
    );
    await Geolocator.openLocationSettings();
  }

  /// Ouvre les paramètres de l'application
  static Future<void> openAppSettings() async {
    AppLogger.i(
      'LocationPermissionService: Ouverture des paramètres de l\'application',
    );
    await Geolocator.openAppSettings();
  }

  // Dialogues d'information
  static Future<void> _showLocationServiceDialog(BuildContext context) async {
    if (!context.mounted) return;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Services de localisation désactivés'),
          content: const Text(
            'Pour ajouter une poubelle, vous devez activer les services de localisation. '
            'Cela nous permettra de positionner précisément la poubelle sur la carte.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openLocationSettings();
              },
              child: const Text('Activer'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    if (!context.mounted) return;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission de localisation requise'),
          content: const Text(
            'Pour ajouter une poubelle, nous avons besoin de votre permission pour accéder à votre position. '
            'Cela nous permettra de placer la poubelle exactement où vous vous trouvez.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => _handlePermissionRequest(context),
              child: const Text('Autoriser'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _handlePermissionRequest(BuildContext context) async {
    if (!context.mounted) return;
    Navigator.of(context).pop();
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permission refusée. Impossible d\'ajouter une poubelle.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<void> _showPermissionPermanentlyDeniedDialog(
    BuildContext context,
  ) async {
    if (!context.mounted) return;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Permission de localisation refusée définitivement',
          ),
          content: const Text(
            'Vous avez refusé définitivement l\'accès à la localisation. '
            'Pour ajouter des poubelles, vous devez activer manuellement cette permission dans les paramètres.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Paramètres'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _showLowAccuracyDialog(
    BuildContext context,
    double accuracy,
  ) async {
    if (!context.mounted) return;
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Précision de localisation insuffisante'),
          content: Text(
            'La précision de votre localisation actuelle est de ${accuracy.toStringAsFixed(1)} mètres. '
            'Pour ajouter une poubelle, nous avons besoin d\'une précision d\'au moins 20 mètres. '
            'Essayez de vous déplacer vers un endroit plus dégagé ou attendez quelques secondes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // L'utilisateur peut réessayer
              },
              child: const Text('Réessayer'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _showLocationErrorDialog(
    BuildContext context,
    String error,
  ) async {
    if (!context.mounted) return;
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Erreur de localisation'),
          content: Text(
            'Impossible d\'obtenir votre position actuelle. '
            'Erreur: $error\n\n'
            'Vérifiez que vous êtes dans un endroit dégagé et que votre GPS est activé.',
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
