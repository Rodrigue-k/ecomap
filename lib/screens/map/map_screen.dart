import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show BitmapDescriptor;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../core/app_theme.dart';
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
  bool _isLoading = true;

  // Conversion between LatLng types
  gmaps.LatLng _toGoogleMapsLatLng(latlong.LatLng latLng) {
    return gmaps.LatLng(latLng.latitude, latLng.longitude);
  }

  latlong.LatLng _toLatlongLatLng(gmaps.LatLng latLng) {
    return latlong.LatLng(latLng.latitude, latLng.longitude);
  }

  @override
  void initState() {
    super.initState();
    _checkAndRequestLocation(); // Vérifier la localisation au démarrage
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
  setState(() => _isLoading = true);

  // Vérifier si les services de localisation sont activés
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildCustomDialog(
        title: 'Localisation désactivée',
        content: 'Les services de localisation sont requis pour utiliser EcoMap. Veuillez les activer.',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quitter'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('Activer'),
          ),
        ],
      ),
    );

    if (result == false) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'EcoMap nécessite la localisation pour fonctionner. Veuillez activer la localisation pour continuer.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    // Ouvrir les paramètres de localisation
    await Geolocator.openLocationSettings();

    // Écouter les changements de statut du service de localisation
    Completer<bool> completer = Completer<bool>();
    StreamSubscription<ServiceStatus>? subscription;
    subscription = Geolocator.getServiceStatusStream().listen(
      (status) {
        print('Service status changed: $status');
        if (status == ServiceStatus.enabled) {
          completer.complete(true);
          subscription?.cancel();
        }
      },
      onError: (e) {
        print('Error in service status stream: $e');
        completer.complete(false);
        subscription?.cancel();
      },
    );

    // Attendre l'activation ou un timeout
    bool activated = await completer.future.timeout(
      const Duration(seconds: 15), // Réduit à 15s pour éviter un blocage long
      onTimeout: () {
        subscription?.cancel();
        return false;
      },
    );

    if (!activated) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La localisation n\'a pas été activée.')),
      );
      return; // Ne pas relancer automatiquement pour éviter les boucles
    }
  }

  // Vérifier les permissions de localisation
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      bool? result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildCustomDialog(
          title: 'Permission refusée',
          content: 'EcoMap nécessite l\'accès à votre localisation pour fonctionner. Veuillez accorder la permission.',
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Quitter'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );

      if (result == false) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'EcoMap nécessite la localisation pour fonctionner. Veuillez accorder la permission pour continuer.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La permission de localisation est toujours refusée.')),
        );
        return;
      }
    }
  }

  if (permission == LocationPermission.deniedForever) {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildCustomDialog(
        title: 'Permission refusée définitivement',
        content: 'La permission de localisation est requise. Veuillez l\'activer dans les paramètres de l\'application.',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quitter'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Paramètres'),
          ),
        ],
      ),
    );

    if (result == false) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'EcoMap nécessite la localisation pour fonctionner. Veuillez activer la permission dans les paramètres.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    await Geolocator.openAppSettings();
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La permission de localisation est toujours refusée.')),
      );
      return;
    }
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
        _isLoading = false;
      });
      _centerMap();
      _updateMarkers(ref.read(wasteBinsProvider).value ?? []);
    }
  } catch (e) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la récupération de la position : $e')),
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
  final wasteBins = ref.watch(wasteBinsProvider).value ?? [];

  return Scaffold(
    appBar: AppBar(
      title: const Text('Carte EcoMap'),
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : gmaps.GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              _centerMap();
            },
            initialCameraPosition: gmaps.CameraPosition(
              target: _currentLocation != null
                  ? _toGoogleMapsLatLng(_currentLocation!)
                  : const gmaps.LatLng(6.2126841, 1.1997389),
              zoom: 12,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
          ),
    floatingActionButton: FloatingActionButton(
      onPressed: _centerMap,
      tooltip: 'Recentrer sur ma position',
      child: const Icon(Icons.gps_fixed),
    ),
  );
}

  @override
void dispose() {
  _mapController?.dispose();
  super.dispose();
}
}


