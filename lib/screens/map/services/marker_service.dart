import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as latlong;
import 'package:EcoMap/models/waste_bin.dart';
import 'package:EcoMap/services/google_maps_service.dart';

class MarkerService {
  // Convertit un LatLng personnalisé en LatLng de Google Maps
  static gmaps.LatLng toGoogleMapsLatLng(latlong.LatLng latLng) {
    return gmaps.LatLng(latLng.latitude, latLng.longitude);
  }

  // Crée un marqueur pour une poubelle
  static Future<gmaps.Marker> createWasteBinMarker(
    WasteBin bin,
    Function() onTap,
  ) async {
    final markerIcon = await GoogleMapsService.getMarkerIcon(null);

    return gmaps.Marker(
      markerId: gmaps.MarkerId(bin.id),
      position: gmaps.LatLng(bin.location.latitude, bin.location.longitude),
      icon: markerIcon,
      infoWindow: gmaps.InfoWindow(
        title: 'Poubelle #${bin.id.substring(0, 5)}',
      ),
      onTap: onTap,
    );
  }

  // Crée un marqueur pour la position actuelle
  static Future<gmaps.Marker> createCurrentLocationMarker(
    latlong.LatLng position,
    Function() onTap,
  ) async {
    final currentLocationIcon = await gmaps.BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 1.0, size: Size(35, 35)),
      'assets/images/current_location.png',
    );

    return gmaps.Marker(
      markerId: const gmaps.MarkerId('current_location'),
      position: toGoogleMapsLatLng(position),
      icon: currentLocationIcon,
      infoWindow: const gmaps.InfoWindow(title: 'Votre position'),
      onTap: onTap,
    );
  }
}
