import 'dart:async';
import 'package:ecomap/presentation/widgets/search_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:latlong2/latlong.dart' as lat_lng;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart'; // CORRECT

import 'package:ecomap/core/services/location_service.dart' as custom_loc;
import 'package:ecomap/domain/entities/waste_dump.dart';
import 'package:ecomap/presentation/providers/waste_dump_provider.dart';
import 'package:ecomap/presentation/widgets/waste_dump_details_bottom_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with WidgetsBindingObserver {
  final custom_loc.LocationService _locationService = custom_loc.LocationService();
  final fm.MapController _mapController = fm.MapController();
  final lat_lng.LatLng _defaultLocation = const lat_lng.LatLng(6.1333, 1.2167); // Lomé
  Position? _currentLocation;
  double _currentZoom = 15.0;
  late final AppLifecycleListener _appLifecycleListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appLifecycleListener = AppLifecycleListener(onResume: _onAppResumed);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeLocation());
  }

  @override
  void dispose() {
    _mapController.dispose();
    _appLifecycleListener.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _onAppResumed() async => await _initializeLocation();

  Future<void> _initializeLocation() async {
    if (!mounted) return;
    try {
      final enabled = await _locationService.isLocationServiceEnabled();
      if (!enabled) {
        _showPermanentSnackBar('La localisation est désactivée. Activez-la.', isLocationDisabled: true);
        return;
      }
      final position = await _locationService.getCurrentPosition();
      if (mounted) {
        setState(() => _currentLocation = position);
        _centerMap(lat_lng.LatLng(position.latitude, position.longitude));
      }
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    }
  }

  void _centerMap(lat_lng.LatLng position) => _mapController.move(position, _currentZoom);

  void _showErrorSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showInfoSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 3)));
  }

  void _showPermanentSnackBar(String msg, {bool isLocationDisabled = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(days: 1),
        action: isLocationDisabled
            ? SnackBarAction(
          label: 'ACTIVER',
          onPressed: () async {
            await Geolocator.openLocationSettings();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        )
            : null,
      ),
    );
  }

  void _showWasteDumpDetails(WasteDump dump) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WasteDumpDetailsBottomSheet(dump: dump),
    );
  }

  WasteDump? _findClosestDump(lat_lng.LatLng point, List<WasteDump> dumps) {
    WasteDump? closest;
    double minDist = double.infinity;
    for (final dump in dumps) {
      final dist = Geolocator.distanceBetween(point.latitude, point.longitude, dump.latitude, dump.longitude);
      if (dist < minDist && dist < 50) {
        minDist = dist;
        closest = dump;
      }
    }
    return closest;
  }

  Color _getClusterColor(double avgArea) {
    if (avgArea < 20) return const Color(0xFF2196F3);
    if (avgArea < 40) return const Color(0xFF4CAF50);
    if (avgArea < 60) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  Widget _legendRow(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wasteDumpsAsync = ref.watch(wasteDumpsProvider);
    final dumps = wasteDumpsAsync.value ?? [];

    final center = _currentLocation != null
        ? lat_lng.LatLng(_currentLocation!.latitude, _currentLocation!.longitude)
        : _defaultLocation;

    final heatMapPoints = dumps
        .map((d) => WeightedLatLng(lat_lng.LatLng(d.latitude, d.longitude), d.surfaceArea))
        .toList();

    final showHeatmap = heatMapPoints.isNotEmpty;

    final heatmapRadius = (50 / (1 + (_currentZoom - 15).abs())).round().clamp(10, 100);

    return Stack(
      children: [
        fm.FlutterMap(
          mapController: _mapController,
          options: fm.MapOptions(
            initialCenter: center,
            initialZoom: _currentZoom,
            minZoom: 4.0,
            maxZoom: 18.0,
            onPositionChanged: (pos, _) => setState(() => _currentZoom = pos.zoom ?? 15.0),
            onTap: (_, point) {
              if (_currentZoom >= 12) {
                final closest = _findClosestDump(point, dumps);
                if (closest != null) _showWasteDumpDetails(closest);
              }
            },
          ),
          children: [
            fm.TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),

            // HEATMAP (zoom local)
            if (showHeatmap && _currentZoom >= 12)
              HeatMapLayer(
                heatMapDataSource: InMemoryHeatMapDataSource(data: heatMapPoints),
                heatMapOptions: HeatMapOptions(
                  radius: heatmapRadius.toDouble(),
                  minOpacity: 0.5,
                  gradient: {0.0: Colors.blue, 0.4: Colors.green, 0.7: Colors.yellow, 1.0: Colors.red},
                ),
              ),

            // CLUSTERING (zoom continental)
            if (dumps.isNotEmpty && _currentZoom < 12)
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 80,
                  size: const Size(50, 50),
                  //fitBoundsOptions: const FitBoundsOptions(padding: [50, 50]),
                  markers: dumps
                      .map((d) => fm.Marker(
                    point: lat_lng.LatLng(d.latitude, d.longitude),
                    width: 50,
                    height: 50,
                    child: const SizedBox.shrink(),
                  ))
                      .toList(),
                  builder: (context, markers) {
                    final total = markers.length;
                    final avgArea = markers.fold<double>(0, (sum, m) {
                      final dump = dumps.firstWhere((d) =>
                      d.latitude == m.point.latitude && d.longitude == m.point.longitude);
                      return sum + dump.surfaceArea;
                    }) /
                        total;

                    return GestureDetector(
                      onTap: () {
                        final bounds = fm.LatLngBounds.fromPoints(markers.map((m) => m.point).toList());
                        _mapController.fitCamera(fm.CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getClusterColor(avgArea),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          total.toString(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
              ),

            fm.RichAttributionWidget(
              attributions: [
                fm.TextSourceAttribution('OpenStreetMap', onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright'))),
              ],
            ),
          ],
        ),

        // Légende
        Positioned(
          bottom: 160,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 10)
            ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_currentZoom >= 12 ? 'Densité de pollution' : 'Clusters', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _legendRow(const Color(0xFF2196F3), '< 20 m²'),
                _legendRow(const Color(0xFF4CAF50), '20–40 m²'),
                _legendRow(const Color(0xFFFF9800), '40–60 m²'),
                _legendRow(const Color(0xFFF44336), '> 60 m²'),
              ],
            ),
          ),
        ),

        // UI
        Positioned(top: MediaQuery.of(context).padding.top + 16, left: 0, right: 0, child: SearchBarWidget(onChanged: (_) {}, onTap: () {})),
        Positioned(
          bottom: 100,
          right: 16,
          child: Column(children: [
            FloatingActionButton.small(heroTag: 'zoom_in', onPressed: () => _mapController.move(_mapController.camera.center, ++_currentZoom), child: const Icon(Icons.add)),
            const SizedBox(height: 8),
            FloatingActionButton.small(heroTag: 'zoom_out', onPressed: () => _mapController.move(_mapController.camera.center, --_currentZoom), child: const Icon(Icons.remove)),
            const SizedBox(height: 16),
            FloatingActionButton(heroTag: 'location', onPressed: _initializeLocation, backgroundColor: Colors.white, child: const Icon(Icons.my_location, color: Colors.black87)),

          SizedBox(height: 30,)
          ]
          ),
        ),

        if (wasteDumpsAsync.isLoading) const Center(child: CircularProgressIndicator()),
        if (wasteDumpsAsync.hasValue && dumps.isEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withAlpha(230), borderRadius: BorderRadius.circular(12)),
              child: const Text('Aucune donnée dans cette zone', style: TextStyle(color: Colors.grey)),
            ),
          ),
      ],
    );
  }
}