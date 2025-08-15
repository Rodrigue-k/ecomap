import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../../models/waste_bin.dart';
import '../../providers/waste_bin_provider.dart';
import '../../services/google_maps_service.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  gmaps.GoogleMapController? _mapController;
  latlong.LatLng? _currentLocation;
  final Set<gmaps.Marker> _markers = {};
  bool _isLoading = false; // La carte s'affiche immédiatement
  bool _locationPermissionGranted = false;

  // Emplacement par défaut (Lomé, Togo)
  final latlong.LatLng _defaultCenter = latlong.LatLng(6.1333, 1.2167);

  // Conversion between LatLng types
  gmaps.LatLng _toGoogleMapsLatLng(latlong.LatLng latLng) {
    return gmaps.LatLng(latLng.latitude, latLng.longitude);
  }

  @override
  void initState() {
    super.initState();
    // D'abord charger les poubelles
    _loadWasteBins();
    // Puis demander immédiatement la localisation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestLocation();
    });
  }

  Future<void> _loadWasteBins() async {
    // S'assure que le provider a fini de charger
    await ref.read(wasteBinsProvider.future);
    final bins = ref.read(wasteBinsProvider).value ?? [];
    _updateMarkers(bins);
  }

  // Méthode pour créer un dialogue stylisé
  Widget _buildCustomDialog({
    required String title,
    required String content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        content,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
      ),
      actions: actions.map((action) {
        if (action is TextButton) {
          return TextButton(
            style: TextButton.styleFrom(
              foregroundColor:
                  action.style?.foregroundColor?.resolve({}) ??
                  AppTheme.primaryColor,
              textStyle: Theme.of(context).textTheme.bodyLarge,
            ),
            onPressed: action.onPressed,
            child: action.child!,
          );
        }
        return action;
      }).toList(),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }

  Future<void> _checkAndRequestLocation() async {
    if (!mounted) return;

    // Vérifier si les services de localisation sont activés
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Demander d'activer les services de localisation
      bool? shouldOpenSettings = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildCustomDialog(
          title: 'Localisation désactivée',
          content: 'Les services de localisation sont nécessaires pour une meilleure expérience. Voulez-vous les activer ?',
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Plus tard'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Activer'),
            ),
          ],
        ),
      );

      if (shouldOpenSettings == true) {
        await Geolocator.openLocationSettings();
      }
      
      if (mounted) {
        setState(() => _locationPermissionGranted = false);
      }
      return;
    }

    // Vérifier et demander les permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Demande explicite de permission
      permission = await Geolocator.requestPermission();
      
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _locationPermissionGranted = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('La localisation est nécessaire pour une meilleure expérience')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // L'utilisateur a refusé définitivement, on propose d'aller dans les paramètres
      bool? openSettings = await showDialog<bool>(
        context: context,
        builder: (context) => _buildCustomDialog(
          title: 'Permission refusée',
          content: 'La localisation est nécessaire. Veuillez l\'activer dans les paramètres de l\'application.',
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Paramètres'),
            ),
          ],
        ),
      );

      if (openSettings == true) {
        await Geolocator.openAppSettings();
      }
      
      if (mounted) {
        setState(() => _locationPermissionGranted = false);
      }
      return;
    }

    // Permission accordée
    if (mounted) {
      setState(() => _locationPermissionGranted = true);
    }

    // Récupérer la position actuelle
    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );
      if (mounted) {
        setState(() {
          _currentLocation = latlong.LatLng(
            position.latitude,
            position.longitude,
          );
        });
        _centerMap();
        _updateMarkers(ref.read(wasteBinsProvider).value ?? []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la récupération de la position : $e'),
          ),
        );
      }
    }
  }

  void _centerMap() {
    if (_currentLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          _toGoogleMapsLatLng(_currentLocation!),
          15,
        ),
      );
    }
  }

  void _showBinOptions(WasteBin bin) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      backgroundColor: AppTheme.surfaceColor,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorColor),
              title: Text(
                'Supprimer cette poubelle',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteBin(bin);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: AppTheme.textSecondary),
              title: Text(
                'Annuler',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteBin(WasteBin bin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildCustomDialog(
        title: 'Confirmer la suppression',
        content: 'Voulez-vous vraiment supprimer cette poubelle ?',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(wasteBinsProvider.notifier).deleteWasteBin(bin.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Poubelle supprimée avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
        }
      }
    }
  }

  Future<void> _updateMarkers(List<WasteBin> bins) async {
    // Éviter les mises à jour si les données n'ont pas changé
    final currentBins = ref.read(wasteBinsProvider).value ?? [];
    if (currentBins == bins && _markers.isNotEmpty) return;

    final markerIcon = await GoogleMapsService.getMarkerIcon(null);
    final currentLocationIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(35, 35)),
      'assets/images/current_location.png',
    );

    final markers = {
      ...bins.map(
        (bin) => gmaps.Marker(
          markerId: gmaps.MarkerId(bin.id),
          position: gmaps.LatLng(bin.location.latitude, bin.location.longitude),
          icon: markerIcon,
          infoWindow: gmaps.InfoWindow(
            title: 'Poubelle #${bin.id.substring(0, 5)}',
          ),
          onTap: () => _showBinOptions(bin),
        ),
      ),
      if (_currentLocation != null)
        gmaps.Marker(
          markerId: const gmaps.MarkerId('current_location'),
          position: _toGoogleMapsLatLng(_currentLocation!),
          icon: currentLocationIcon,
          infoWindow: const gmaps.InfoWindow(title: 'Votre position'),
          onTap: _showAddBinDialog,
        ),
    };

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(markers);
      });
    }
  }

  void _showAddBinDialog() {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Position actuelle non disponible. Veuillez réessayer.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _buildCustomDialog(
        title: 'Ajouter une poubelle',
        content:
            'Ajouter une poubelle à votre position actuelle :\n'
            'Lat: ${_currentLocation!.latitude.toStringAsFixed(6)}, '
            'Lon: ${_currentLocation!.longitude.toStringAsFixed(6)}',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(wasteBinsProvider.notifier)
                    .addWasteBin(_currentLocation!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Poubelle ajoutée avec succès'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Observer le provider pour reconstruire le widget quand les données changent
    ref.watch(wasteBinsProvider).when(
          data: (bins) => _updateMarkers(bins),
          loading: () {},
          error: (e, s) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de chargement des poubelles: $e')),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Carte EcoMap')),
      body: Stack(
        children: [
          gmaps.GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              _centerMap(); // Centrer la carte lors de sa création
            },
            initialCameraPosition: gmaps.CameraPosition(
              target: _toGoogleMapsLatLng(_currentLocation ?? _defaultCenter),
              zoom: 12,
            ),
            myLocationEnabled: _locationPermissionGranted,
            myLocationButtonEnabled: false,
            markers: _markers,
          ),
          if (!_locationPermissionGranted)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: MaterialBanner(
                backgroundColor: AppTheme.surfaceColor.withOpacity(0.9),
                content: const Text(
                  'Activez la localisation pour une meilleure expérience.',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      await Geolocator.openAppSettings();
                    },
                    child: const Text('PARAMÈTRES'),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          onPressed: _centerMap,
          tooltip: 'Recentrer sur ma position',
          child: const Icon(Icons.gps_fixed),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
