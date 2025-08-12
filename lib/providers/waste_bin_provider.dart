import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/waste_bin.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';

// Provider pour la position actuelle de l'utilisateur
final currentLocationProvider = FutureProvider<LatLng?>((ref) async {
  return await LocationService.getCurrentLocation();
});

// Provider pour toutes les poubelles
final wasteBinsProvider = StreamProvider<List<WasteBin>>((ref) {
  return FirebaseService.getWasteBins();
});

// Provider pour les poubelles à proximité
final nearbyWasteBinsProvider = StreamProvider.family<List<WasteBin>, LatLng>((ref, center) {
  return FirebaseService.getWasteBinsNearby(center, 5.0); // 5km de rayon
});

// Provider pour la poubelle sélectionnée
final selectedWasteBinProvider = StateProvider<WasteBin?>((ref) => null);

// Provider pour le type de poubelle sélectionné lors de l'ajout
final selectedBinTypeProvider = StateProvider<String>((ref) => 'general');

// Provider pour le statut de chargement
final isLoadingProvider = StateProvider<bool>((ref) => false);

// Provider pour les erreurs
final errorProvider = StateProvider<String?>((ref) => null);

// Provider pour filtrer les poubelles par type
final filteredWasteBinsProvider = Provider<List<WasteBin>>((ref) {
  final wasteBins = ref.watch(wasteBinsProvider).value ?? [];
  final selectedType = ref.watch(selectedBinTypeProvider);
  
  if (selectedType == 'all') {
    return wasteBins;
  }
  
  return wasteBins.where((bin) => bin.type == selectedType).toList();
});

// Provider pour les statistiques
final statsProvider = Provider<Map<String, dynamic>>((ref) {
  final wasteBins = ref.watch(wasteBinsProvider).value ?? [];
  
  if (wasteBins.isEmpty) {
    return {
      'total': 0,
      'general': 0,
      'recyclable': 0,
      'organic': 0,
      'available': 0,
      'full': 0,
      'maintenance': 0,
    };
  }
  
  final int total = wasteBins.length;
  final int general = wasteBins.where((bin) => bin.type == 'general').length;
  final int recyclable = wasteBins.where((bin) => bin.type == 'recyclable').length;
  final int organic = wasteBins.where((bin) => bin.type == 'organic').length;
  final int available = wasteBins.where((bin) => bin.status == 'available').length;
  final int full = wasteBins.where((bin) => bin.status == 'full').length;
  final int maintenance = wasteBins.where((bin) => bin.status == 'maintenance').length;
  
  return {
    'total': total,
    'general': general,
    'recyclable': recyclable,
    'organic': organic,
    'available': available,
    'full': full,
    'maintenance': maintenance,
  };
});
