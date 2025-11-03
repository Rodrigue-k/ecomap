import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapsService {
  static Future<BitmapDescriptor> _getCustomMarkerIcon() async {
    const ImageConfiguration imageConfiguration = ImageConfiguration(
      size: Size(16, 16),
    );
    final BitmapDescriptor bitmapDescriptor = await BitmapDescriptor.asset(
      imageConfiguration,
      'assets/images/trash-bin_map.png',
    );
    return bitmapDescriptor;
  }

  static Future<BitmapDescriptor> _getCurrentLocationIcon() async {
    const ImageConfiguration imageConfiguration = ImageConfiguration(
      size: Size(20, 20), // Taille différente pour la position actuelle
    );
    final BitmapDescriptor bitmapDescriptor = await BitmapDescriptor.asset(
      imageConfiguration,
      'assets/images/current_location.png',
    );
    return bitmapDescriptor;
  }

  static BitmapDescriptor? _cachedMarkerIcon;
  static BitmapDescriptor? _cachedCurrentLocationIcon;

  static Future<BitmapDescriptor> getTrashBinIcon() async {
    _cachedMarkerIcon ??= await _getCustomMarkerIcon();
    return _cachedMarkerIcon!;
  }

  static Future<BitmapDescriptor> getCurrentLocationIcon() async {
    _cachedCurrentLocationIcon ??= await _getCurrentLocationIcon();
    return _cachedCurrentLocationIcon!;
  }

  static Future<BitmapDescriptor> getMarkerIcon(String? binType) async {
    return await getTrashBinIcon();
  }

  static Circle createRadiusCircle(LatLng center, double radiusKm) {
    return Circle(
      circleId: const CircleId('radius'),
      center: center,
      radius: radiusKm * 1000,
      fillColor: Colors.blue.withOpacity(0.2),
      strokeColor: Colors.blue,
      strokeWidth: 2,
    );
  }
}
