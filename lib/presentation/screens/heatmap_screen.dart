import 'package:ecomap/presentation/controllers/location_controller.dart';
import 'package:ecomap/presentation/providers/waste_dump_provider.dart';
import 'package:ecomap/presentation/widgets/waste_heatmap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlong;

class HeatmapScreen extends ConsumerWidget {
  const HeatmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wasteDumpsAsync = ref.watch(wasteDumpsProvider);
    final currentLocation = ref.watch(locationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte des dépôts sauvages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(wasteDumpsProvider),
          ),
        ],
      ),
      body: wasteDumpsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
        data: (wasteDumps) {
          // Convertir les WasteDump en données pour la heatmap
          final wasteLocations = wasteDumps
              .map((dump) => latlong.LatLng(dump.latitude, dump.longitude))
              .toList();

          final wasteData = <latlong.LatLng, WasteDumpData>{};
          for (final dump in wasteDumps) {
            wasteData[latlong.LatLng(
              dump.latitude,
              dump.longitude,
            )] = WasteDumpData(
              photoUrl: dump.photoUrl,
              timestamp: dump.timestamp,
              surfaceArea: dump.surfaceArea,
              status: dump.status,
              description: dump.description,
              reportedBy: dump.reportedBy,
              tags: dump.tags,
            );
          }

          return WasteHeatmap(
            wasteLocations: wasteLocations,
            wasteData: wasteData,
            currentLocation: currentLocation.whenOrNull(
              data: (location) =>
                  latlong.LatLng(location.latitude, location.longitude),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Naviguer vers l'écran de signalement
          // Navigator.pushNamed(context, '/report');
        },
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Signaler un dépôt'),
      ),
    );
  }
}
