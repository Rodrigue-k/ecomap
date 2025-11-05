import 'package:ecomap/core/services/google_maps_service.dart';
import 'package:ecomap/domain/entities/waste_bin.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as latlong;

class MarkerService {
  static gmaps.LatLng toGoogleMapsLatLng(latlong.LatLng latLng) {
    return gmaps.LatLng(latLng.latitude, latLng.longitude);
  }

  static Future<gmaps.Marker> createWasteBinMarker(
    WasteBin bin,
    VoidCallback onTap,
  ) async {
    final icon = await GoogleMapsService.getTrashBinIcon();
    
    return gmaps.Marker(
      markerId: gmaps.MarkerId('bin_${bin.id}'),
      position: gmaps.LatLng(bin.latitude, bin.longitude),
      icon: icon,
      onTap: onTap,
      infoWindow: gmaps.InfoWindow(
        title: 'Poubelle',
        snippet: 'Appuyez pour plus d\'options',
      ),
    );
  }

  static Future<gmaps.Marker> createCurrentLocationMarker(
    latlong.LatLng position,
    VoidCallback onTap,
  ) async {
    final icon = await GoogleMapsService.getCurrentLocationIcon();
    
    return gmaps.Marker(
      markerId: const gmaps.MarkerId('current_location'),
      position: gmaps.LatLng(position.latitude, position.longitude),
      icon: icon,
      onTap: onTap,
      anchor: const Offset(0.5, 0.5),
      zIndex: 1000,
    );
  }
}