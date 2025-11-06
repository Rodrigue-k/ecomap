import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import 'package:ecomap/core/services/location_service.dart' as custom_loc;
import 'package:ecomap/domain/entities/waste_dump.dart';
import 'package:ecomap/presentation/providers/waste_dump_provider.dart';
import 'package:ecomap/presentation/controllers/map_controller.dart';
import 'package:ecomap/presentation/widgets/waste_dump_details_bottom_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with WidgetsBindingObserver {
  final custom_loc.LocationService _locationService =
      custom_loc.LocationService();
  gmaps.GoogleMapController? _mapController;
  final gmaps.LatLng _defaultLocation = const gmaps.LatLng(
    6.1333,
    1.2167,
  ); // Lomé, Togo
  late final AppLifecycleListener _appLifecycleListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Configurer l'écouteur du cycle de vie de l'application
    _appLifecycleListener = AppLifecycleListener(onResume: _onAppResumed);

    // Initialiser la localisation après le premier rendu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _appLifecycleListener.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Appelé quand l'application revient au premier plan
  Future<void> _onAppResumed() async {
    debugPrint(
      'Application revenue au premier plan, rafraîchissement des données...',
    );
    await _initializeLocation();
  }

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
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation de la localisation: $e');
    }
  }

  void _showWasteDumpDetails(WasteDump dump) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WasteDumpDetailsBottomSheet(wasteDump: dump),
    );
  }

  Future<void> _centerMap(gmaps.LatLng position) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(position, 15),
      );
    }
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  void _showPermanentSnackBar(
    String message, {
    bool isLocationDisabled = false,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(days: 1), // Snackbar permanente
      action: isLocationDisabled
          ? SnackBarAction(
              label: 'ACTIVER',
              onPressed: () async {
                await Geolocator.openLocationSettings();
                if (mounted) {
                  scaffoldMessenger.hideCurrentSnackBar();
                }
              },
            )
          : null,
    );

    scaffoldMessenger.showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapControllerProvider);
    final wasteDumpsAsync = ref.watch(wasteDumpsProvider);

    return Stack(
      children: [
        gmaps.GoogleMap(
          initialCameraPosition: gmaps.CameraPosition(
            target: gmaps.LatLng(
              state.currentLocation?.latitude ?? _defaultLocation.latitude,
              state.currentLocation?.longitude ?? _defaultLocation.longitude,
            ),
            zoom: 15,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
            // Appliquer le style personnalisé si nécessaire
            // controller.setMapStyle(_getMapStyle());
          },
          onTap: (_) {
            // Gérer les appuis sur la carte si nécessaire
          },
          heatmaps: wasteDumpsAsync.when(
            data: (dumps) {
              return {
                gmaps.Heatmap(
                  heatmapId: const gmaps.HeatmapId('waste_dumps_heatmap'),
                  data: dumps.map((dump) => gmaps.WeightedLatLng(
                    gmaps.LatLng(dump.latitude, dump.longitude),
                  )).toList(),
                  radius: const gmaps.HeatmapRadius.fromPixels(50),
                  opacity: 0.7,
                ),
              };
            },
            loading: () => {},
            error: (_, __) => {},
          ),
        ),

        // Bouton de recentrage
        Positioned(
          top: 100,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouton de localisation
              FloatingActionButton(
                heroTag: 'center_location',
                onPressed: () {
                  if (state.currentLocation != null) {
                    _centerMap(
                      gmaps.LatLng(
                        state.currentLocation!.latitude,
                        state.currentLocation!.longitude,
                      ),
                    );
                  }
                },
                backgroundColor: Colors.white,
                child: const Icon(Icons.gps_fixed, color: Colors.black),
              ),
              const SizedBox(height: 16),
              // Bouton pour signaler un nouveau dépotoir
              FloatingActionButton(
                heroTag: 'report_dump',
                onPressed: () async {
                  final result = await context.pushNamed<bool>('report-dump');

                  if (result == true) {
                    // Rafraîchir la liste des dépotoirs
                    ref.invalidate(wasteDumpsProvider);
                    _showInfoSnackBar('Dépotoir signalé avec succès!');
                  }
                },
                backgroundColor: Colors.red,
                child: const Icon(Icons.add_location_alt, color: Colors.white),
              ),
            ],
          ),
        ),

        // Indicateur de chargement
        if (state.status == MapStatus.loading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
