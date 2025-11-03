import 'package:flutter/material.dart';

class LocationNotObtainedWidget extends StatelessWidget {
  final bool hasPermission;
  final VoidCallback onGetLocation;

  const LocationNotObtainedWidget({
    super.key,
    required this.hasPermission,
    required this.onGetLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasPermission ? Icons.location_off : Icons.location_disabled,
            size: 64,
            color: hasPermission ? Colors.orange : Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            hasPermission
                ? 'Aucune localisation obtenue'
                : 'Permission de localisation requise',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hasPermission
                ? 'Appuyez sur le bouton ci-dessous pour localiser'
                : 'Appuyez sur "Autoriser" pour continuer',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
