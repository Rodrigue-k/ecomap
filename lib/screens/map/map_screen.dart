import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';

import 'package:EcoMap/core/theme/app_theme.dart';
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
  bool _isLoading = true;
  
  // Position par défaut (Lomé, Togo)
  static const _defaultLocation = latlong.LatLng(6.1333, 1.2167);
  
  late final AppLifecycleListener _appLifecycleListener;
  
  @override
  void initState() {
    super.initState();
    
    // Configurer l'écouteur du cycle de vie de l'application
    _appLifecycleListener = AppLifecycleListener(
      onResume: _onAppResumed,
    );
    
    // Charger les données après le premier rendu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Charger les poubelles
      _loadWasteBins();
      
      // Initialiser la localisation
      _initializeLocation();
    });
  }
  
  // Charge les poubelles indépendamment de la localisation
  void _loadWasteBins() {
    if (!mounted) return;
    
    // Déclencher le chargement des poubelles via le Provider
    // La mise à jour de l'interface sera gérée par le Consumer dans le build
    ref.read(wasteBinsProvider);
  }
  
  Future<void> _onAppResumed() async {
    debugPrint('Application revenue au premier plan, vérification de la localisation...');
    await _checkAndUpdateLocation();
  }
  
  Future<void> _checkAndUpdateLocation() async {
    try {
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (serviceEnabled) {
        final permission = await _locationService.checkPermission();
        if (permission == LocationPermission.whileInUse || 
            permission == LocationPermission.always) {
          final position = await _locationService.getCurrentPosition();
          if (mounted) {
            setState(() {
              _currentLocation = position;
            });
            _centerMap();
            _updateCurrentLocationMarker();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la position: $e');
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _appLifecycleListener.dispose();
    super.dispose();
  }

  // Initialise la localisation et charge les données
  Future<void> _initializeLocation() async {
    try {
      // Ne pas bloquer le chargement des poubelles sur la localisation
      _isLoading = false;
      
      // Essayer d'obtenir la position actuelle en arrière-plan
      _tryGetCurrentLocation();
      
    } catch (e) {
      debugPrint('Erreur dans _initializeLocation: $e');
      _isLoading = false;
    }
  }
  
  // Essaie d'obtenir la position actuelle sans bloquer l'interface
  Future<void> _tryGetCurrentLocation() async {
    try {
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      
      var permission = await _locationService.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _locationService.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        
        final position = await _locationService.getCurrentPosition();
        if (!mounted) return;
        
        setState(() {
          _currentLocation = position;
          _updateCurrentLocationMarker();
          _centerMap();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la position: $e');
      // Ne pas afficher de message d'erreur pour ne pas gêner l'utilisateur
    }
  }

  // Centre la carte sur la position actuelle ou sur la position de test
  void _centerMap() {
    final position = _currentLocation ?? _defaultLocation;
    _mapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(
        MarkerService.toGoogleMapsLatLng(position),
        _currentLocation != null ? 15 : 12, // Zoom plus large si pas de localisation
      ),
    );
  }

  // Affiche un message de succès
  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Affiche un message d'erreur
  void _showError(String title, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Vérifie et met à jour la position actuelle
  /*Future<void> _checkAndUpdateLocation() async {
    try {
      if (await _locationService.isLocationServiceEnabled()) {
        final permission = await _locationService.checkPermission();
        if (permission == LocationPermission.denied) {
          await _locationService.requestPermission();
        } else if (permission == LocationPermission.whileInUse || 
                  permission == LocationPermission.always) {
          final position = await _locationService.getCurrentPosition();
          if (mounted) {
            setState(() {
              _currentLocation = position;
            });
            _updateCurrentLocationMarker();
            _centerMap();
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification de la localisation: $e');
    }
  }*/

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
            const SizedBox(height: 8), // Ajoute un espace en bas pour les appareils avec notch
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
      final currentLocationMarker = await MarkerService.createCurrentLocationMarker(
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
      content: 'Ajouter une poubelle à votre position actuelle ?\n'
          'Lat: ${_currentLocation!.latitude.toStringAsFixed(6)}\n'
          'Lon: ${_currentLocation!.longitude.toStringAsFixed(6)}',
      confirmText: 'Ajouter',
    );

    if (confirmed && mounted) {
      try {
        await ref.read(wasteBinsProvider.notifier).addWasteBin(_currentLocation!);
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
    debugPrint('Création de la carte avec ${_markers.length} marqueurs');
    
    // Utiliser la position actuelle si disponible, sinon utiliser la position de test
    final initialPosition = _currentLocation ?? _defaultLocation;
    debugPrint('Position initiale de la carte: ${initialPosition.latitude}, ${initialPosition.longitude}');
    
    // Créer la position initiale de la caméra
    final cameraPosition = gmaps.CameraPosition(
      target: MarkerService.toGoogleMapsLatLng(initialPosition),
      zoom: _currentLocation != null ? 15 : 12, // Zoom plus large si pas de localisation
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte EcoMap'),
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) {
                  debugPrint('Erreur lors du chargement des poubelles: $error');
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
          
          // Indicateur de chargement
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
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
    );
  }
}
