import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'add_bin_controller.dart';
import 'widgets/location_card.dart';

class AddBinScreen extends ConsumerWidget {
  const AddBinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addBinControllerProvider);
    final controller = ref.read(addBinControllerProvider.notifier);

    // Création de fonctions wrapper sans paramètre
    Future<void> handleGetLocation() => controller.getCurrentLocation(context);
    Future<void> handleCheckPermission() =>
        controller.checkLocationPermission(context);
    Future<void> handleAddBin() => controller.addWasteBin(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une poubelle'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Carte de localisation
            LocationCard(
              state: state,
              onGetLocation: handleGetLocation,
              onAddBin: handleAddBin,
            ),

            const SizedBox(height: 24),

            // Bouton de localisation actuelle
            ElevatedButton.icon(
              onPressed: state.hasLocationPermission
                  ? handleGetLocation
                  : handleCheckPermission,
              icon: Icon(
                state.hasLocationPermission
                    ? Icons.my_location
                    : Icons.location_disabled,
              ),
              label: Text(
                state.hasLocationPermission
                    ? 'Actualiser ma position'
                    : 'Autoriser la localisation',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: state.hasLocationPermission
                    ? Colors.blue
                    : Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Informations
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Recensement rapide',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• Pointez simplement votre position pour ajouter une poubelle\n'
              '• La localisation doit être précise (idéalement ≤20m)\n'
              '• Vous pourrez ajouter plus de détails plus tard\n'
              '• Toutes les poubelles sont visibles sur la carte',
              style: TextStyle(color: Colors.blue[700]),
            ),
          ],
        ),
      ),
    );
  }
}
