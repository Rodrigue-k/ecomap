import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as latlong;

class CoordinateConverter {
  static gmaps.LatLng toGoogleMapsLatLng(latlong.LatLng latLng) {
    return gmaps.LatLng(latLng.latitude, latLng.longitude);
  }

  static latlong.LatLng toLatlongLatLng(gmaps.LatLng latLng) {
    return latlong.LatLng(latLng.latitude, latLng.longitude);
  }
}