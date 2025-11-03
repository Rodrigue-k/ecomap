import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart'
    hide LocationServiceDisabledException, PermissionDeniedException;

import 'package:EcoMap/core/theme/app_theme.dart';
import 'package:EcoMap/core/widgets/snack_bar_manager.dart';
import 'package:EcoMap/models/waste_bin.dart';
import 'package:EcoMap/providers/waste_bin_provider.dart';
import 'package:EcoMap/screens/map/services/location_service.dart';
import 'package:EcoMap/screens/map/services/marker_service.dart';
import 'package:EcoMap/screens/map/widgets/custom_dialogs.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final LocationService _locationService = LocationService();
  gmaps.GoogleMapController? _mapController;
  latlong.LatLng? _currentLocation;
  final Set<gmaps.Marker> _markers = {};

  // Position par défaut (Lomé, Togo)
  static const _defaultLocation = latlong.LatLng(6.1333, 1.2167);

  late final AppLifecycleListener _appLifecycleListener;

  @override
  void initState() {
    super.initState();

    // Configurer l'écouteur du cycle de vie de l'application
    _appLifecycleListener = AppLifecycleListener(onResume: _onAppResumed);

    // Charger les données après le premier rendu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Charger les poubelles
      _loadWasteBins(showLoading: false);

      // Initialiser la localisation
      _initializeLocation();
    });
  }

  // Charge les poubelles indépendamment de la localisation
  Future<void> _loadWasteBins({bool showLoading = true}) async {
    if (!mounted) return;

    if (showLoading) {
      // Afficher un indicateur de chargement si demandé
      _showInfoSnackBar('Mise à jour des poubelles en cours...');
    }

    try {
      // Déclencher le chargement des poubelles via le Provider
      final result = ref.refresh(wasteBinsProvider.future);
      await result;
    } catch (e) {
      debugPrint('Erreur lors du chargement des poubelles: $e');
      if (mounted) {
        _showInfoSnackBar('Erreur lors du chargement des données');
      }
    }
  }

  // Appelé quand l'application revient au premier plan
  Future<void> _onAppResumed() async {
    debugPrint(
      'Application revenue au premier plan, rafraîchissement des données...',
    );
    // Rafraîchir les données
    await _loadWasteBins(showLoading: true);
    // Vérifier et mettre à jour la localisation
    await _initializeLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _appLifecycleListener.dispose();
    super.dispose();
  }

  // Initialise la localisation et gère l'affichage des notifications
  Future<void> _initializeLocation() async {
    if (!mounted) return;

    try {
      // Vérifier si la localisation est activée
      final isLocationEnabled = await _locationService
          .isLocationServiceEnabled();
      if (!isLocationEnabled) {
        _showPermanentSnackBar(
          'La localisation est désactivée. Activez-la pour voir votre position.',
          isLocationDisabled: true,
        );
        return;
      }

      // Vérifier les permissions
      var permission = await _locationService.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _locationService.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermanentSnackBar(
          'Les permissions de localisation sont nécessaires pour afficher votre position.',
          isLocationDisabled: false,
        );
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Si la permission est accordée, masquer la SnackBar et obtenir la position
        SnackBarManager.hideCurrentSnackBar();
        await _tryGetCurrentLocation();
      }
    } catch (e) {
      debugPrint('Erreur dans _initializeLocation: $e');
      _showError('Erreur', 'Impossible d\'accéder à la localisation');
    }
  }

  // Essaie d'obtenir la position actuelle
  Future<void> _tryGetCurrentLocation() async {
    if (!mounted) return;

    try {
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        _currentLocation = position;
        _updateCurrentLocationMarker();
        _centerMap();
      });

      // Cacher toute notification de localisation en cas de succès
      SnackBarManager.hideCurrentSnackBar();
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la position: $e');
      if (e is LocationServiceDisabledException) {
        _showPermanentSnackBar(
          'La localisation est désactivée. Activez-la pour voir votre position.',
        );
      } else if (e is PermissionDeniedException) {
        _showPermanentSnackBar('L\'accès à la localisation a été refusé.');
      } else {
        _showPermanentSnackBar(
          'Impossible d\'obtenir votre position. Vérifiez votre connexion et les paramètres de localisation.',
        );
      }
    }
  }

  // Centre la carte sur la position actuelle ou sur la position de test
  void _centerMap() {
    final position = _currentLocation ?? _defaultLocation;
    _mapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(
        MarkerService.toGoogleMapsLatLng(position),
        _currentLocation != null
            ? 15
            : 12, // Zoom plus large si pas de localisation
      ),
    );
  }

  // Affiche un message de succès
  void _showSuccess(String message) {
    if (!mounted) return;
    SnackBarManager.showSuccessSnackBar(message);
  }

  // Affiche un message d'erreur
  void _showError(String title, String message) {
    if (!mounted) return;
    SnackBarManager.showErrorSnackBar('$title: $message');
  }

  // Affiche un message d'information persistant avec une action appropriée
  void _showPermanentSnackBar(
    String message, {
    bool isLocationDisabled = true,
  }) {
    if (!mounted) return;

    SnackBarManager.showPermanentSnackBar(
      message,
      action: SnackBarAction(
        label: isLocationDisabled ? 'Activer la localisation' : 'Paramètres',
        textColor: Colors.white,
        onPressed: () async {
          if (isLocationDisabled) {
            // Ouvrir les paramètres de localisation
            await _locationService.openLocationSettings();
          } else {
            // Ouvrir les paramètres de l'application pour les permissions
            await _locationService.openAppSettings();
          }

          // Vérifier à nouveau l'état après le retour des paramètres
          if (mounted) {
            await _initializeLocation();
          }
        },
      ),
    );
  }

  // Affiche un message d'information
  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    // Masquer d'abord les éventuelles notifications existantes
    SnackBarManager.hideCurrentSnackBar();
    // Afficher la nouvelle notification
    SnackBarManager.showInfoSnackBar(message);
  }

  // Méthode pour rafraîchir toutes les données
  Future<void> _refreshData() async {
    await _loadWasteBins(showLoading: true);
    await _initializeLocation();
  }

  // Affiche les options pour une poubelle
  void _showBinOptions(WasteBin bin) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      backgroundColor: AppTheme.surfaceColor,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorColor),
              title: const Text('Supprimer cette poubelle'),
              onTap: () {
                Navigator.pop(context);
                _deleteBin(bin);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: AppTheme.textSecondary),
              title: const Text('Annuler'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(
              height: 8,
            ), // Ajoute un espace en bas pour les appareils avec notch
          ],
        ),
      ),
    );
  }

  // Supprime une poubelle après confirmation
  Future<void> _deleteBin(WasteBin bin) async {
    final confirmed = await CustomDialogs.showConfirmationDialog(
      context: context,
      title: 'Confirmer la suppression',
      content: 'Voulez-vous vraiment supprimer cette poubelle ?',
      confirmText: 'Supprimer',
    );

    if (confirmed && mounted) {
      try {
        await ref.read(wasteBinsProvider.notifier).deleteWasteBin(bin.id);
        if (mounted) {
          _showSuccess('Poubelle supprimée avec succès');
        }
      } catch (e) {
        if (mounted) {
          _showError('Erreur', 'Impossible de supprimer la poubelle : $e');
        }
      }
    }
  }

  // Met à jour les marqueurs des poubelles
  Future<void> _updateWasteBinMarkers(List<WasteBin> bins) async {
    if (!mounted) return;

    debugPrint('Mise à jour de ${bins.length} marqueurs de poubelles');

    try {
      final markers = <gmaps.Marker>[];

      // Créer les marqueurs de manière séquentielle pour éviter les problèmes de concurrence
      for (final bin in bins) {
        try {
          final marker = await MarkerService.createWasteBinMarker(
            bin,
            () => _showBinOptions(bin),
          );
          markers.add(marker);
        } catch (e) {
          debugPrint('Erreur création marqueur poubelle ${bin.id}: $e');
        }
      }

      if (!mounted) return;

      setState(() {
        // Supprimer uniquement les marqueurs de poubelles
        _markers.removeWhere((m) => m.markerId.value != 'current_location');
        _markers.addAll(markers);
        debugPrint('${_markers.length} marqueurs affichés sur la carte');
      });
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour des marqueurs: $e');
    }
  }

  // Met à jour le marqueur de position actuelle
  Future<void> _updateCurrentLocationMarker() async {
    if (!mounted || _currentLocation == null) return;

    try {
      final currentLocationMarker =
          await MarkerService.createCurrentLocationMarker(
            _currentLocation!,
            _showAddBinDialog,
          );

      if (mounted) {
        setState(() {
          // Supprimer l'ancien marqueur de position
          _markers.removeWhere((m) => m.markerId.value == 'current_location');
          _markers.add(currentLocationMarker);
        });
      }
    } catch (e) {
      debugPrint('Erreur mise à jour marqueur position: $e');
    }
  }

  // Affiche la boîte de dialogue pour ajouter une poubelle
  Future<void> _showAddBinDialog() async {
    if (_currentLocation == null) {
      _showError('Erreur', 'Position actuelle non disponible');
      return;
    }

    final confirmed = await CustomDialogs.showConfirmationDialog(
      context: context,
      title: 'Ajouter une poubelle',
      content:
          'Ajouter une poubelle à votre position actuelle ?\n'
          'Lat: ${_currentLocation!.latitude.toStringAsFixed(6)}\n'
          'Lon: ${_currentLocation!.longitude.toStringAsFixed(6)}',
      confirmText: 'Ajouter',
    );

    if (confirmed && mounted) {
      try {
        await ref
            .read(wasteBinsProvider.notifier)
            .addWasteBin(_currentLocation!);
        if (mounted) {
          _showSuccess('Poubelle ajoutée avec succès');
        }
      } catch (e) {
        if (mounted) {
          _showError('Erreur', 'Impossible d\'ajouter la poubelle : $e');
        }
      }
    }
  }

  // Construit la carte Google Maps
  Widget _buildMap() {
    final initialPosition = _currentLocation ?? _defaultLocation;

    // Créer la position initiale de la caméra
    final cameraPosition = gmaps.CameraPosition(
      target: MarkerService.toGoogleMapsLatLng(initialPosition),
      zoom: _currentLocation != null
          ? 15
          : 12, // Zoom plus large si pas de localisation
    );

    return Stack(
      children: [
        gmaps.GoogleMap(
          onMapCreated: (controller) {
            _mapController = controller;
            debugPrint('Carte créée avec succès');

            // Centrer la carte sur la position initiale
            _centerMap();

            // Vérifier la région visible après un court délai
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && _mapController != null) {
                _mapController!.getVisibleRegion().then((region) {
                  debugPrint('Région visible après création: $region');
                });
              }
            });
          },
          initialCameraPosition: cameraPosition,
          myLocationEnabled: _currentLocation != null,
          myLocationButtonEnabled: false,
          markers: _markers,
          onTap: (_) {
            // Gérer les appuis sur la carte si nécessaire
          },
          onCameraIdle: () {
            // Vérifier la région visible quand la caméra s'arrête de bouger
            if (_mapController != null) {
              _mapController!.getVisibleRegion().then((region) {
                debugPrint('Région visible après déplacement: $region');
              });
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: SnackBarManager.scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Carte EcoMap'),
          actions: [
            // Bouton de rafraîchissement
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshData,
              tooltip: 'Rafraîchir les données',
            ),
          ],
        ),
        body: Stack(
          children: [
            // Carte Google Maps
            Consumer(
              builder: (context, ref, child) {
                // Observer les changements de la liste des poubelles
                final wasteBinsAsync = ref.watch(wasteBinsProvider);

                // Mettre à jour les marqueurs quand les données changent
                return wasteBinsAsync.when(
                  data: (bins) {
                    if (mounted) {
                      // Utiliser un délai pour éviter les mises à jour pendant le build
                      Future.microtask(() => _updateWasteBinMarkers(bins));
                    }
                    return _buildMap();
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) {
                    debugPrint(
                      'Erreur lors du chargement des poubelles: $error',
                    );
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Erreur lors du chargement des poubelles'),
                          TextButton(
                            onPressed: _loadWasteBins,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 100.0, right: 0.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'gps_button',
                onPressed: _centerMap,
                tooltip: 'Recentrer sur ma position',
                child: const Icon(Icons.gps_fixed),
              ),
              const SizedBox(height: 16),
              FloatingActionButton(
                heroTag: 'add_bin_button',
                onPressed: _showAddBinDialog,
                tooltip: 'Ajouter une poubelle',
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
