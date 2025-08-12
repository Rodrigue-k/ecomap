import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/waste_bin.dart';
import '../services/location_permission_service.dart';
import '../core/app_theme.dart';
import '../core/app_logger.dart';

class AddBinScreen extends ConsumerStatefulWidget {
  const AddBinScreen({super.key});

  @override
  ConsumerState<AddBinScreen> createState() => _AddBinScreenState();
}

class _AddBinScreenState extends ConsumerState<AddBinScreen> {
  LatLng? _selectedLocation;
  bool _isLoading = false;
  bool _isLocationLoading = false;
  bool _hasLocationPermission = false;
  String _locationProgressMessage = '';
  double _locationAccuracy = 0.0;

  @override
  void initState() {
    super.initState();
    AppLogger.i('AddBinScreen: Initialisation');
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    AppLogger.i('AddBinScreen: Vérification des permissions de localisation');
    final hasPermission =
        await LocationPermissionService.requestLocationPermissionForAddingBin(
          context,
        );
    setState(() {
      _hasLocationPermission = hasPermission;
    });

    if (hasPermission) {
      await _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!_hasLocationPermission) {
      AppLogger.w('AddBinScreen: Pas de permission de localisation');
      await _checkLocationPermission();
      return;
    }

    setState(() {
      _isLocationLoading = true;
      _locationProgressMessage = 'Initialisation...';
    });

    try {
      AppLogger.i('AddBinScreen: Début de l\'obtention de la localisation');

      // Utiliser la nouvelle méthode avec progrès
      final position = await LocationPermissionService.getLocationWithProgress(
        context,
        (String progressMessage) {
          if (mounted) {
            setState(() {
              _locationProgressMessage = progressMessage;
            });
          }
        },
      );

      if (position != null) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _locationAccuracy = position.accuracy;
          _isLocationLoading = false;
          _locationProgressMessage = 'Position obtenue !';
        });

        AppLogger.i(
          'AddBinScreen: Localisation réussie - Précision: ${position.accuracy}m',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Position obtenue avec une précision de ${position.accuracy.toStringAsFixed(1)}m',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        setState(() {
          _isLocationLoading = false;
          _locationProgressMessage = 'Échec de la localisation';
        });

        AppLogger.w('AddBinScreen: Échec de l\'obtention de la localisation');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Impossible d\'obtenir votre position. Vérifiez vos paramètres de localisation.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'AddBinScreen: Erreur lors de l\'obtention de la localisation',
        e,
        stackTrace,
      );
      setState(() {
        _isLocationLoading = false;
        _locationProgressMessage = 'Erreur de localisation';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de localisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addWasteBin() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord obtenir votre position actuelle.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      AppLogger.i('AddBinScreen: Ajout de la poubelle');

      // Generate a unique ID for the new waste bin
      final docRef = FirebaseFirestore.instance.collection('waste_bins').doc();

      final wasteBin = WasteBin(
        id: docRef.id,
        location: _selectedLocation!,
        createdAt: DateTime.now(),
      );

      await docRef.set(wasteBin.toFirestore());

      AppLogger.i('AddBinScreen: Poubelle ajoutée avec succès');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Poubelle ajoutée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/');
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'AddBinScreen: Erreur lors de l\'ajout de la poubelle',
        e,
        stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildLocationCard() {
    return Card(
      elevation: 4,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: _isLocationLoading
            ? _buildLocationLoadingState()
            : _selectedLocation == null
            ? _buildLocationNotObtainedState()
            : _buildLocationObtainedState(),
      ),
    );
  }

  Widget _buildLocationLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _locationProgressMessage,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Assurez-vous d\'être tout près de la poubelle',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'GPS en cours d\'initialisation...',
            style: TextStyle(fontSize: 10, color: Colors.blue),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationNotObtainedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _hasLocationPermission
                ? Icons.location_off
                : Icons.location_disabled,
            size: 64,
            color: _hasLocationPermission ? Colors.orange : Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _hasLocationPermission
                ? 'Aucune localisation obtenue'
                : 'Permission de localisation requise',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _hasLocationPermission
                ? 'Appuyez sur le bouton ci-dessous pour localiser'
                : 'Appuyez sur "Autoriser" pour continuer',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationObtainedState() {
    final accuracyColor = _locationAccuracy <= 10
        ? Colors.green
        : _locationAccuracy <= 20
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
              'Précision: ${_locationAccuracy.toStringAsFixed(1)}m',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: accuracyColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _addWasteBin,
            icon: _isLoading
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
              _isLoading ? 'Ajout en cours...' : 'Ajouter cette poubelle',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
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

  @override
  Widget build(BuildContext context) {
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
            _buildLocationCard(),

            const SizedBox(height: 24),

            // Bouton de localisation actuelle
            ElevatedButton.icon(
              onPressed: _hasLocationPermission
                  ? _getCurrentLocation
                  : _checkLocationPermission,
              icon: Icon(
                _hasLocationPermission
                    ? Icons.my_location
                    : Icons.location_disabled,
              ),
              label: Text(
                _hasLocationPermission
                    ? 'Actualiser ma position'
                    : 'Autoriser la localisation',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasLocationPermission
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
            Card(
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
            ),
          ],
        ),
      ),
    );
  }
}
