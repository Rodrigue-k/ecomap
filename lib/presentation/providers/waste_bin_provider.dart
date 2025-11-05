import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/waste_bin.dart';
import '../../data/repositories/waste_bin_repository_impl.dart';
import '../../core/services/location_service.dart';

// Provider for the current user location
final currentLocationProvider = FutureProvider<LatLng?>((ref) async {
  return await LocationService().getCurrentPosition();
});

// Main provider for waste bins
final wasteBinsProvider = StreamProvider<List<WasteBin>>((ref) {
  final repository = ref.watch(wasteBinRepositoryProvider);
  return repository.getWasteBins();
});

// Provider for the selected waste bin
final selectedWasteBinProvider = StateProvider<WasteBin?>((ref) => null);

// Provider for the adding mode
final isAddingBinProvider = StateProvider<bool>((ref) => false);
