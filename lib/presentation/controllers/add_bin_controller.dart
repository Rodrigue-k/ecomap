import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // No longer used

import '../../core/services/location_permission_service.dart';
import '../../core/app_logger.dart';
import '../../data/repositories/waste_bin_repository_impl.dart'; // Import repository

class AddBinState {
  final LatLng? selectedLocation;
  final bool isLoading;
  final bool isLocationLoading;
  final bool hasLocationPermission;
  final String locationProgressMessage;
  final double locationAccuracy;

  const AddBinState({
    this.selectedLocation,
    this.isLoading = false,
    this.isLocationLoading = false,
    this.hasLocationPermission = false,
    this.locationProgressMessage = '',
    this.locationAccuracy = 0.0,
  });

  AddBinState copyWith({
    LatLng? selectedLocation,
    bool? isLoading,
    bool? isLocationLoading,
    bool? hasLocationPermission,
    String? locationProgressMessage,
    double? locationAccuracy,
  }) {
    return AddBinState(
      selectedLocation: selectedLocation ?? this.selectedLocation,
      isLoading: isLoading ?? this.isLoading,
      isLocationLoading: isLocationLoading ?? this.isLocationLoading,
      hasLocationPermission:
          hasLocationPermission ?? this.hasLocationPermission,
      locationProgressMessage:
          locationProgressMessage ?? this.locationProgressMessage,
      locationAccuracy: locationAccuracy ?? this.locationAccuracy,
    );
  }
}

class AddBinController extends StateNotifier<AddBinState> {
  AddBinController(this.ref) : super(const AddBinState());

  final Ref ref;

  Future<void> checkLocationPermission(BuildContext context) async {
    AppLogger.i('Vérification des permissions de localisation');
    final hasPermission =
        await LocationPermissionService.requestLocationPermissionForAddingBin(
          context,
        );

    state = state.copyWith(hasLocationPermission: hasPermission);

    if (hasPermission) {
      if (context.mounted) {
        await getCurrentLocation(context);
      }
    }
  }

  Future<void> getCurrentLocation(BuildContext context) async {
    if (!state.hasLocationPermission) {
      AppLogger.w('Pas de permission de localisation');
      return;
    }

    state = state.copyWith(
      isLocationLoading: true,
      locationProgressMessage: 'Initialisation...',
    );

    try {
      AppLogger.i('Début de l\'obtention de la localisation');

      final position = await LocationPermissionService.getLocationWithProgress(
        context,
        (String progressMessage) {
          state = state.copyWith(locationProgressMessage: progressMessage);
        },
      );

      if (position != null) {
        state = state.copyWith(
          selectedLocation: LatLng(position.latitude, position.longitude),
          locationAccuracy: position.accuracy,
          isLocationLoading: false,
          locationProgressMessage: 'Position obtenue !',
        );

        AppLogger.i('Localisation réussie - Précision: ${position.accuracy}m');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Position obtenue avec une précision de ${position.accuracy.toStringAsFixed(1)}m',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (context.mounted) {
          _handleLocationError(context, 'Échec de la localisation');
        }
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'Erreur lors de l\'obtention de la localisation',
        e,
        stackTrace,
      );
      if (context.mounted) {
        _handleLocationError(context, 'Erreur de localisation: $e');
      }
    }
  }

  void _handleLocationError(BuildContext context, String message) {
    state = state.copyWith(
      isLocationLoading: false,
      locationProgressMessage: message,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> addWasteBin(BuildContext context) async {
    if (state.selectedLocation == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez d\'abord obtenir votre position actuelle.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      AppLogger.i('Ajout de la poubelle');

      final repository = ref.read(wasteBinRepositoryProvider);
      await repository.addWasteBin(
        latitude: state.selectedLocation!.latitude,
        longitude: state.selectedLocation!.longitude,
        imageUrl: 'https://placehold.co/600x400.png', // Placeholder
      );

      AppLogger.i('Poubelle ajoutée avec succès');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poubelle ajoutée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/');
      }
    } catch (e, stackTrace) {
      AppLogger.e('Erreur lors de l\'ajout de la poubelle', e, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final addBinControllerProvider =
    StateNotifierProvider<AddBinController, AddBinState>(
      (ref) => AddBinController(ref),
    );
