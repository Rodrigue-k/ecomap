import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationStatusWidget extends StatefulWidget {
  final VoidCallback? onLocationUpdated;

  const LocationStatusWidget({super.key, this.onLocationUpdated});

  @override
  State<LocationStatusWidget> createState() => _LocationStatusWidgetState();
}

class _LocationStatusWidgetState extends State<LocationStatusWidget> {
  bool _isLoading = false;
  LocationPermission _permission = LocationPermission.denied;
  bool _serviceEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  Future<void> _checkLocationStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _serviceEnabled = await Geolocator.isLocationServiceEnabled();
      _permission = await Geolocator.checkPermission();
    } catch (e) {
      // Gérer l'erreur
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final newPermission = await Geolocator.requestPermission();
      setState(() {
        _permission = newPermission;
      });

      if (newPermission == LocationPermission.whileInUse ||
          newPermission == LocationPermission.always) {
        widget.onLocationUpdated?.call();
      }
    } catch (e) {
      // Gérer l'erreur
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
    _checkLocationStatus();
  }

  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
    _checkLocationStatus();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Vérification de la localisation...'),
            ],
          ),
        ),
      );
    }

    if (!_serviceEnabled) {
      return Card(
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_off, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Services de localisation désactivés',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Veuillez activer les services de localisation pour utiliser la carte.',
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _openLocationSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Activer la localisation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_permission == LocationPermission.denied) {
      return Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Permission de localisation requise',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Cette application a besoin de votre permission pour accéder à votre position.',
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _requestPermission,
                icon: const Icon(Icons.location_on),
                label: const Text('Autoriser la localisation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_permission == LocationPermission.deniedForever) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.block, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Permission de localisation refusée définitivement',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Vous avez refusé définitivement l\'accès à la localisation. Veuillez l\'activer manuellement.',
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _openAppSettings,
                icon: const Icon(Icons.settings_applications),
                label: const Text('Ouvrir les paramètres'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_permission == LocationPermission.whileInUse ||
        _permission == LocationPermission.always) {
      return Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text(
                'Localisation activée',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _checkLocationStatus,
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualiser',
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
