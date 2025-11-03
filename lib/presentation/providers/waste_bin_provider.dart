import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../models/waste_bin.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';

// Provider pour la position actuelle de l'utilisateur
final currentLocationProvider = FutureProvider<LatLng?>((ref) async {
  return await LocationService.getCurrentLocation();
});

// Provider principal pour les poubelles
final wasteBinsProvider =
    StreamNotifierProvider<WasteBinsNotifier, List<WasteBin>>(
      WasteBinsNotifier.new,
    );

class WasteBinsNotifier extends StreamNotifier<List<WasteBin>> {
  @override
  Stream<List<WasteBin>> build() {
    return FirebaseService.getWasteBins();
  }

  Future<void> addWasteBin(latlong.LatLng location) async {
    state = const AsyncValue.loading();
    try {
      await FirebaseService.addWasteBin(location);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteWasteBin(String id) async {
    state = const AsyncValue.loading();
    try {
      await FirebaseService.deleteWasteBin(id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

// Provider pour la poubelle sélectionnée
final selectedWasteBinProvider = StateProvider<WasteBin?>((ref) => null);

// Provider pour le mode d'ajout
final isAddingBinProvider = StateProvider<bool>((ref) => false);
