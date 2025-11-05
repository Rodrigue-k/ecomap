import 'package:ecomap/core/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';

import '../../core/widgets/snack_bar_manager.dart';
import 'map/services/marker_service.dart';


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
      // Initialiser la localisation
      _initializeLocation();
    });
  }


  // Appelé quand l'application revient au premier plan
  Future<void> _onAppResumed() async {
    debugPrint(
      'Application revenue au premier plan, rafraîchissement des données...',
    );
    // Rafraîchir les données
    // await _loadWasteBins(showLoading: true);
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

  // Affiche un message indiquant que la fonctionnalité est désactivée
  void _showAddBinDialog() {
    _showInfoSnackBar('Ajout de poubelle temporairement désactivé');
  }

  // Style personnalisé pour la carte
  String _getMapStyle() {
    return '''
    [
      {
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#f5f5f5"
          }
        ]
      },
      {
        "elementType": "labels.icon",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#2E7D32"
          }
        ]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#f5f5f5"
          }
        ]
      },
      {
        "featureType": "administrative.land_parcel",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#bdbdbd"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#eeeeee"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#e5e5e5"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#9e9e9e"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#ffffff"
          }
        ]
      },
      {
        "featureType": "road.arterial",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#C8E6C9"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#A5D6A7"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry.stroke",
        "stylers": [
          {
            "color": "#81C784"
          }
        ]
      },
      {
        "featureType": "road.local",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#E8F5E9"
          }
        ]
      },
      {
        "featureType": "transit.line",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#e5e5e5"
          }
        ]
      },
      {
        "featureType": "transit.station",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#eeeeee"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#B3E5FC"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#039BE5"
          }
        ]
      }
    ]
    ''';
  }

  // Construit la carte Google Maps
  Widget _buildMap() {
    final initialPosition = _currentLocation ?? _defaultLocation;
    final cameraPosition = gmaps.CameraPosition(
      target: MarkerService.toGoogleMapsLatLng(initialPosition),
      zoom: _currentLocation != null ? 15.0 : 12.0,
    );

    return Stack(
      children: [
        gmaps.GoogleMap(
          initialCameraPosition: cameraPosition,
          myLocationEnabled: _currentLocation != null,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapType: gmaps.MapType.normal,
          style: _getMapStyle(),
          padding: const EdgeInsets.only(bottom: 100), // Ajout de padding en bas pour la barre de navigation
          markers: _markers,
          onMapCreated: (controller) {
            _mapController = controller;
            _updateCurrentLocationMarker();
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

  // Gère la sélection d'un élément de la barre de navigation
  int _selectedIndex = 0;

  // Construit un élément de la barre de navigation
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) {
        _showInfoSnackBar('Fonctionnalité des signalements à venir !');
      } else if (index == 2) {
        _showInfoSnackBar('Profil utilisateur à venir !');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: SnackBarManager.scaffoldMessengerKey,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('EcoMap'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        body: Stack(
          children: [
            _buildMap(),
            // Barre de navigation flottante
            Positioned(
              left: 20,
              right: 20,
              bottom: 30,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9E9E9E).withAlpha(76), // 30% d'opacité
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.map_rounded, 'Carte'),
                    _buildNavItem(1, Icons.report_problem_rounded, 'Signalements'),
                    _buildNavItem(2, Icons.person_rounded, 'Profil'),
                  ],
                ),
              ),
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
