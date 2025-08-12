import 'dart:async';
import 'package:EcoMap/config/google_maps_config.dart';
import 'package:EcoMap/models/waste_bin.dart';
import 'package:EcoMap/services/location_service.dart';
import 'package:EcoMap/services/waste_bin_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:logger/logger.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Logger _logger = Logger();
  GoogleMapController? _mapController;
  final WasteBinService _wasteBinService = WasteBinService();

  LatLng? _currentLocation;
  final Set<Marker> _markers = {};
  List<WasteBin> _wasteBins = [];

  static const CameraPosition _kDefaultLocation = CameraPosition(
    target: LatLng(6.2126841, 1.1997389),
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    _logger.i('MapScreen.initState');
    _getCurrentLocation();
    _loadWasteBins();
  }

  Future<void> _getCurrentLocation() async {
    _logger.i('Requesting current location...');
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            _currentLocation!,
            15.0, // Zoom codé en dur
          ),
        );
        _logger.i('Current location found: $_currentLocation');
      } else {
        _logger.w('Could not get current location.');
        setState(() {
          _currentLocation = _kDefaultLocation.target;
        });
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(_kDefaultLocation),
        );
      }
    } catch (e) {
      _logger.e('Error getting current location: $e');
      setState(() {
        _currentLocation = _kDefaultLocation.target;
      });
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(_kDefaultLocation),
      );
    }
  }

  Future<void> _loadWasteBins() async {
    _logger.i('Loading waste bins...');
    try {
      _wasteBins = await _wasteBinService.getWasteBins().first;
      _buildMarkers();
      _logger.i('Waste bins loaded: ${_wasteBins.length}');
    } catch (e) {
      _logger.e('Error loading waste bins: $e');
    }
  }

  void _buildMarkers() {
    final Set<Marker> markers = {};
    for (var bin in _wasteBins) {
      markers.add(
        Marker(
          markerId: MarkerId(bin.id),
          position: LatLng(bin.location.latitude, bin.location.longitude),
          infoWindow: InfoWindow(
            title: bin.name ?? 'Poubelle non nommée',
            snippet:
                'Type: ${bin.type ?? 'Non spécifié'} - Status: ${bin.status ?? 'Disponible'}',
          ),
          onTap: () {
            _logger.i('Tapped on marker: ${bin.name ?? 'Poubelle non nommée'}');
          },
        ),
      );
    }
    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
    _logger.d('Markers built: ${_markers.length}');
  }

  @override
  void dispose() {
    _logger.i('MapScreen.dispose');
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EcoMap')),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
          if (_currentLocation != null) {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(
                _currentLocation!,
                15.0, // Zoom codé en dur
              ),
            );
          } else {
            _mapController?.animateCamera(
              CameraUpdate.newCameraPosition(_kDefaultLocation),
            );
          }
        },
        initialCameraPosition: _kDefaultLocation,
        mapType: MapType.normal,
        myLocationButtonEnabled: true,
        myLocationEnabled: true,
        zoomControlsEnabled: true,
        markers: _markers,
        liteModeEnabled: GoogleMapsConfig.liteModeEnabled,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        tooltip: 'My Location',
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
