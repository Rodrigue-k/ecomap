import 'dart:async';
import 'package:ecomap/presentation/widgets/search_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:latlong2/latlong.dart' as lat_lng;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'services/map_layers_controller.dart' as map_controller;
import 'widgets/map_layer_selector.dart';
import 'widgets/air_quality_layer.dart';
import 'package:ecomap/core/services/location_service.dart' as custom_loc;
import 'package:ecomap/domain/entities/waste_dump.dart';
import 'package:ecomap/domain/entities/air_quality_data.dart' as aq_entity;
import 'package:ecomap/presentation/providers/waste_dump_provider.dart';
import 'package:ecomap/presentation/providers/air_quality_provider.dart';
import 'package:ecomap/presentation/providers/air_quality_mock_provider.dart';
import 'package:ecomap/presentation/widgets/waste_dump_details_bottom_sheet.dart';
import 'package:collection/collection.dart'; // Pour firstWhereOrNull

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  Timer? _debounce; // Pour le debouncing des événements de zoom
  final custom_loc.LocationService _locationService = custom_loc.LocationService();
  final fm.MapController _mapController = fm.MapController();
  final PopupController _popupController = PopupController();
  final lat_lng.LatLng _defaultLocation = const lat_lng.LatLng(6.1333, 1.2167); // Lomé
  Position? _currentLocation;
  double _currentZoom = 15.0;
  late final AppLifecycleListener _appLifecycleListener;
  bool _isLegendExpanded = true;
  List<aq_entity.AirQualityData> _airQualityDataList = [];
  bool _mapReady = false; // Flag pour attendre que le map soit rendu

  @override
  void initState() {
    super.initState();
    _appLifecycleListener = AppLifecycleListener(onResume: _onAppResumed);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeLocation());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initializeLocation();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _appLifecycleListener.dispose();
    _mapController.dispose();
    _popupController.dispose();
    super.dispose();
  }

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

  Future<void> _onAppResumed() async {
    await _initializeLocation();
  }

  void _centerMap(lat_lng.LatLng position) => _mapController.move(position, _currentZoom);

  void _showErrorSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
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
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
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

  // Filtre les déchets visibles dans la vue courante
  List<WasteDump> _getVisibleDumps(List<WasteDump>? allDumps, fm.MapCamera camera) {
    if (allDumps == null || allDumps.isEmpty) return [];

    final bounds = camera.visibleBounds;
    return allDumps.where((dump) {
      return bounds.contains(lat_lng.LatLng(dump.latitude, dump.longitude));
    }).toList();
  }

  Widget _legendRow(Color color, String text, {String? description}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200), // Contrainte de largeur maximale
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(top: 1, right: 6),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400, width: 0.5),
                ),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 1.0),
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[700],
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadAirQualityData(lat_lng.LatLng position) async {
    try {
      // Utilisation des données simulées uniquement
      final mockData = ref.read(airQualityMockProvider);
      setState(() {
        _airQualityDataList = mockData;
      });

      // Désactivé l'appel à l'API pour éviter les erreurs 429
      // Les données simulées sont déjà chargées ci-dessus
    } catch (e) {
      debugPrint('Error loading mock air quality data: $e');
      // En cas d'erreur avec les données simulées, on initialise une liste vide
      setState(() {
        _airQualityDataList = [];
      });
    }
  }

  Future<void> _fetchAirQualityForCurrentLocation() async {
    try {
      // Charge les données simulées pour l'Afrique
      final mockData = ref.read(airQualityMockProvider);
      setState(() {
        _airQualityDataList = mockData;
      });

      // Ne pas charger les données pour la position actuelle pour éviter les conflits
      // avec les données africaines

      // Ajuster la vue pour montrer toute l'Afrique
      if (mockData.isNotEmpty) {
        // Calculer les limites pour inclure tous les points africains
        double minLat = mockData.first.latitude;
        double maxLat = mockData.first.latitude;
        double minLng = mockData.first.longitude;
        double maxLng = mockData.first.longitude;

        for (final data in mockData) {
          if (data.latitude < minLat) minLat = data.latitude;
          if (data.latitude > maxLat) maxLat = data.latitude;
          if (data.longitude < minLng) minLng = data.longitude;
          if (data.longitude > maxLng) maxLng = data.longitude;
        }

        // Ajouter une marge autour des points
        final latPadding = (maxLat - minLat) * 0.2;
        final lngPadding = (maxLng - minLng) * 0.2;

        // Ajuster la vue pour montrer toute l'Afrique
        _mapController.fitCamera(
          fm.CameraFit.bounds(
            bounds: fm.LatLngBounds(
              lat_lng.LatLng(minLat - latPadding, minLng - lngPadding),
              lat_lng.LatLng(maxLat + latPadding, maxLng + lngPadding),
            ),
            padding: const EdgeInsets.all(50.0),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des données de qualité de l\'air: $e');
      setState(() {
        _airQualityDataList = [];
      });
    }
  }

  // Trouve les données de qualité de l'air pour un marqueur donné
  aq_entity.AirQualityData? _findAirQualityDataForMarker(fm.Marker marker) {
    try {
      return _airQualityDataList.firstWhere(
              (data) => data.latitude == marker.point.latitude &&
              data.longitude == marker.point.longitude
      );
    } catch (e) {
      return null;
    }
  }

  // Affiche un popup avec les détails de la qualité de l'air
  void _showAirQualityPopup(aq_entity.AirQualityData data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Qualité de l\'air - ${data.statusText}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AQI: ${data.aqi} (${data.statusText})'),
            Text('Polluant principal: ${data.mainPollutant}'),
            Text('Température: ${data.temperature}°C'),
            Text('Humidité: ${data.humidity}%'),
            Text('Pression: ${data.pressure} hPa'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wasteDumpsAsync = ref.watch(wasteDumpsProvider);
    final dumps = wasteDumpsAsync.value ?? [];
    final mapState = ref.watch(map_controller.mapControllerProvider);
    final mapController = ref.read(map_controller.mapControllerProvider.notifier);

    final center = _currentLocation != null
        ? lat_lng.LatLng(_currentLocation!.latitude, _currentLocation!.longitude)
        : _defaultLocation;

    // Get visible dumps based on current map bounds - only if map is ready
    final visibleDumps = _mapReady ? _getVisibleDumps(dumps, _mapController.camera) : [];

    // Points pour la heatmap des déchets (only for visible dumps for better performance)
    final wasteHeatmapPoints = _currentZoom >= 12
        ? visibleDumps
        .map((d) => WeightedLatLng(lat_lng.LatLng(d.latitude, d.longitude), d.surfaceArea))
        .toList()
        : <WeightedLatLng>[];

    // Points pour la qualité de l'air
    final airQualityPoints = _airQualityDataList.isNotEmpty
        ? _airQualityDataList.map((data) => WeightedLatLng(
      lat_lng.LatLng(data.latitude, data.longitude),
      data.pm25?.toDouble() ?? 10.0, // Default to 10.0 if pm25 is null
    )).toList()
        : <WeightedLatLng>[];

    final bool showWasteHeatmap = mapState.selectedLayer == 'dépotoires';
    final bool showAirQualityHeatmap = mapState.selectedLayer == 'air';

    return Stack(
      children: [
        fm.FlutterMap(
          mapController: _mapController,
          options: fm.MapOptions(
            initialCenter: center,
            initialZoom: _currentZoom,
            onMapReady: () {
              if (!_mapReady) {
                setState(() => _mapReady = true);
              }
            },
            onTap: (tapPosition, point) {
              if (mapState.selectedLayer == 'dépotoires') {
                final closestDump = dumps.isNotEmpty ? _findClosestDump(point, dumps) : null;
                if (closestDump != null) {
                  _showWasteDumpDetails(closestDump);
                }
              }
            },
            onPositionChanged: (position, hasGesture) {
              if (hasGesture) {
                // Debounce the update to avoid too many rebuilds
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    setState(() {
                      _currentZoom = position.zoom;
                      // If we're on the air quality layer, fetch data for the new position
                      if (mapState.selectedLayer == 'air') {
                        _loadAirQualityData(position.center);
                      }
                    });
                  }
                });
              }
            },
          ),
          children: [
            fm.TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),

            // HEATMAP des déchets (zoom local)
            if (showWasteHeatmap == true && _currentZoom >= 12 && wasteHeatmapPoints.isNotEmpty)
              HeatMapLayer(
                heatMapDataSource: InMemoryHeatMapDataSource(
                  data: wasteHeatmapPoints,
                ),
                heatMapOptions: HeatMapOptions(
                  radius: (60 / (1 + (_currentZoom - 15).abs())).roundToDouble().clamp(15, 120),
                  minOpacity: 0.7,
                  gradient: {
                    0.1: Colors.blue,
                    0.3: Colors.green,
                    0.6: Colors.yellow,
                    0.9: Colors.orange,
                    1.0: Colors.red,
                  },
                ),
              ),

            // HEATMAP de la qualité de l'air
            if (showAirQualityHeatmap == true && airQualityPoints.isNotEmpty)
              HeatMapLayer(
                heatMapDataSource: InMemoryHeatMapDataSource(
                  data: airQualityPoints,
                ),
                heatMapOptions: HeatMapOptions(
                  radius: 100,
                  minOpacity: 0.5,
                  gradient: {
                    0.0: Colors.blue,
                    0.2: Colors.green,
                    0.4: Colors.yellow,
                    0.6: Colors.red,
                    0.8: Colors.purple,
                    1.0: Colors.brown,
                  },
                ),
              ),

            // Air quality marker layer
            if (showAirQualityHeatmap == true)
              AirQualityLayer(
                airQualityDataList: _airQualityDataList,
                isActive: true,
                popupController: _popupController,
                onMarkerTap: (airQualityData) {
                  _showAirQualityPopup(airQualityData);
                },
              ),

            // Popup for air quality data
            if (showAirQualityHeatmap)
              PopupMarkerLayer(
                options: PopupMarkerLayerOptions(
                  popupController: _popupController,
                  markers: _airQualityDataList.map((data) => fm.Marker(
                    point: lat_lng.LatLng(data.latitude, data.longitude),
                    width: 40,
                    height: 40,
                    child: const SizedBox.shrink(),
                  )).toList(),
                  popupDisplayOptions: PopupDisplayOptions(
                    builder: (BuildContext context, fm.Marker marker) {
                      final data = _findAirQualityDataForMarker(marker);
                      if (data == null) return const SizedBox.shrink();
                      return AirQualityPopup(
                        data: data,
                        onClose: () => _popupController.hideAllPopups(),
                      );
                    },
                  ),
                ),
              ),

            // CLUSTERING - Toujours actif pour les dépotoirs
            if (visibleDumps.isNotEmpty && mapState.selectedLayer == 'dépotoires')
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 80, // Ajuste si nécessaire pour uncluster plus tôt à haut zoom
                  size: const Size(50, 50),
                  padding: const EdgeInsets.all(50),
                  markers: visibleDumps.map((d) => fm.Marker(
                    point: lat_lng.LatLng(d.latitude, d.longitude),
                    width: 40.0,
                    height: 40.0,
                    child: GestureDetector(
                      onTap: () => _showWasteDumpDetails(d),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ombre portée
                          Transform.translate(
                            offset: const Offset(1, 1),
                            child: Icon(
                              Icons.location_on,
                              color: const Color.fromRGBO(0, 0, 0, 0.3),
                              size: 40.0,
                            ),
                          ),
                          // Icône principale
                          Icon(
                            Icons.location_on,
                            color: const Color(0xFF4CAF50).withAlpha(204), // 0.8 * 255 ≈ 204
                            size: 40.0,
                          ),
                          // Point central pour le clic
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                  builder: (context, markers) {
                    final total = markers.length;
                    if (total == 1) {
                      // Pour un seul marqueur, on retourne directement le marqueur
                      return markers.first.child ?? const SizedBox.shrink();
                    }

                    // Pour les clusters, on calcule la surface moyenne
                    final avgArea = markers.fold<double>(0, (sum, m) {
                      final dump = visibleDumps.firstWhereOrNull((d) =>
                      d.latitude == m.point.latitude && d.longitude == m.point.longitude);
                      return sum + (dump == null ? 0 : dump.surfaceArea);
                    }) / total;

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
                            BoxShadow(
                                color: const Color.fromRGBO(0, 0, 0, 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4)
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          total.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16
                          ),
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

        // Légende pour les dépotoirs (uniquement visible quand la couche dépotoirs est sélectionnée)
        if (mapState.selectedLayer == 'dépotoires')
          Positioned(
            bottom: 160,
            left: 16,
            child: Container(
              margin: const EdgeInsets.only(right: 50 ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_currentZoom >= 12 ? 'Densité de pollution' : 'Clusters',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _legendRow(const Color(0xFF2196F3), '< 20 m²'),
                  _legendRow(const Color(0xFF4CAF50), '20–40 m²'),
                  _legendRow(const Color(0xFFFF9800), '40–60 m²'),
                  _legendRow(const Color(0xFFF44336), '> 60 m²'),
                ],
              ),
            ),
          ),

        // Légende pour la qualité de l'air (uniquement visible quand la couche air est sélectionnée)
        if (mapState.selectedLayer == 'air')
          Positioned(
            bottom: 160,
            left: 16,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 220, // Largeur fixe réduite
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 2))],
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isLegendExpanded = !_isLegendExpanded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Row(
                        children: [
                          Icon(Icons.legend_toggle, size: 16, color: Colors.blueGrey[800]),
                          const SizedBox(width: 6),
                          Text(
                            'Légende PM2.5',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                              height: 1.2,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            _isLegendExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: Colors.grey[700],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isLegendExpanded) ...[
                    const Divider(height: 16, thickness: 1),
                    ...ref.read(map_controller.mapControllerProvider.notifier).getAirQualityLegend().map(
                      (item) => _legendRow(
                        item['color'] as Color,
                        '${item['label']} (${item['range']} µg/m³)',
                        description: item['description'] as String,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Source: Données simulées',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

        // Bouton pour charger les données à l'échelle de l'Afrique
        if (mapState.selectedLayer == 'air')
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                // Centrer sur l'Afrique
                _mapController.move(const lat_lng.LatLng(8.7832, 20.5085), 3.0);
                // Charger les données simulées pour l'Afrique
                final mockData = ref.read(airQualityMockProvider);
                setState(() {
                  _airQualityDataList = mockData;
                });

                // Afficher un message à l'utilisateur
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chargement des données de qualité de l\'air pour l\'Afrique...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.public, color: Colors.white),
            ),
          ),

        // UI
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 0,
          right: 0,
          child: Column(
            children: [
              SearchBarWidget(onChanged: (_) {}, onTap: () {}),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: MapLayerSelector(
                  selectedLayer: mapState.selectedLayer,
                  onLayerChanged: (layer) {
                    mapController.changeLayer(layer);

                    // If switching to air quality layer, load data for current position
                    if (layer == 'air' && _currentLocation != null) {
                      _fetchAirQualityForCurrentLocation();
                    } else {
                      // Hide popup when switching away from air quality layer
                      _popupController.hideAllPopups();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
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

        if (mapState.isLoading)
          const Center(child: CircularProgressIndicator()),

        if (mapState.error != null)
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                mapState.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),

        if (wasteDumpsAsync.isLoading)
          const Center(child: CircularProgressIndicator()),

        if ((wasteDumpsAsync.value?.isEmpty ?? true) && !wasteDumpsAsync.isLoading && mapState.selectedLayer == 'dépotoires')
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.9),
                  borderRadius: BorderRadius.circular(12)
              ),
              child: const Text('Aucune donnée dans cette zone', style: TextStyle(color: Colors.grey)),
            ),
          ),
      ],
    );
  }
}