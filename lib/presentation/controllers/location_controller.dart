import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

final locationProvider = StreamProvider.autoDispose<Position>((ref) async* {
  // Vérifier les permissions
  bool serviceEnabled;
  LocationPermission permission;

  // Vérifier si le service de localisation est activé
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Les services de localisation sont désactivés.');
  }

  // Vérifier les autorisations
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Les permissions de localisation sont refusées');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception(
      'Les permissions de localisation sont définitivement refusées.',
    );
  }

  // Obtenir la position actuelle
  final position = await Geolocator.getCurrentPosition();
  yield position;

  // Écouter les mises à jour de position
  await for (final position in Geolocator.getPositionStream()) {
    yield position;
  }
});

final currentLocationProvider = Provider<LatLng?>((ref) {
  final location = ref.watch(locationProvider);
  return location.whenOrNull(
    data: (position) => LatLng(position.latitude, position.longitude),
  );
});
