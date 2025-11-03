import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class LocationObtainedWidget extends StatelessWidget {
  final LatLng location;
  final double accuracy;
  final bool isLoading;
  final VoidCallback onAddBin;

  const LocationObtainedWidget({
    super.key,
    required this.location,
    required this.accuracy,
    required this.isLoading,
    required this.onAddBin,
  });

  @override
  Widget build(BuildContext context) {
    final accuracyColor = accuracy <= 10
        ? Colors.green
        : accuracy <= 20
        ? Colors.orange
        : Colors.red;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on, size: 80, color: accuracyColor),
          const SizedBox(height: 16),
          Text(
            'Localisation obtenue !',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: accuracyColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: accuracyColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Précision: ${accuracy.toStringAsFixed(1)}m',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: accuracyColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Lat: ${location.latitude.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            'Lng: ${location.longitude.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: isLoading ? null : onAddBin,
            icon: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add_location),
            label: Text(
              isLoading ? 'Ajout en cours...' : 'Ajouter cette poubelle',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // Ou votre couleur de thème
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
