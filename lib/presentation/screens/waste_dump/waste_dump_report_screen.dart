import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:ecomap/core/logger/app_logger.dart';
import 'package:ecomap/core/services/permission_service.dart';
import 'package:ecomap/domain/entities/waste_dump.dart';
import 'package:ecomap/core/providers/providers.dart';

class WasteDumpReportScreen extends ConsumerStatefulWidget {
  const WasteDumpReportScreen({super.key});

  @override
  @override
  ConsumerState<WasteDumpReportScreen> createState() =>
      _WasteDumpReportScreenState();
}

class _WasteDumpReportScreenState extends ConsumerState<WasteDumpReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _surfaceController = TextEditingController();
  File? _image;
  Position? _currentPosition;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Vérifier si la localisation est activée
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Les services de localisation sont désactivés';
        });
        // Demander d'activer la localisation
        final shouldOpenSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Localisation requise'),
            content: const Text(
              'Veuillez activer la localisation pour signaler un dépotoir',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Paramètres'),
              ),
            ],
          ),
        );

        if (shouldOpenSettings == true) {
          await Geolocator.openLocationSettings();
        }
        return;
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Les permissions de localisation sont nécessaires';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              'Les permissions de localisation sont définitivement refusées';
        });
        // Rediriger vers les paramètres de l'application
        await openAppSettings();
        return;
      }

      // Obtenir la position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
      });

      AppLogger.d(
        'Position obtenue: ${position.latitude}, ${position.longitude}',
      );
    } catch (e, stackTrace) {
      AppLogger.e(
        'Erreur de géolocalisation',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Impossible d\'obtenir votre position';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      // Vérifier et demander les permissions
      final hasPermission =
          await PermissionService.checkAndRequestCameraPermission();
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permission de la caméra requise pour prendre des photos',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1200,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'Erreur lors de la capture photo',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la capture: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_image == null || _currentPosition == null) {
      setState(() {
        _errorMessage = 'Veuillez prendre une photo et activer la localisation';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final wasteDump = WasteDump(
        id: const Uuid().v4(),
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        surfaceArea: double.parse(_surfaceController.text),
        photoUrl: _image!.path,
        timestamp: DateTime.now(),
      );

      final useCase = ref.read(reportWasteDumpUseCaseProvider);
      await useCase(wasteDump);

      if (mounted) {
        Navigator.of(
          context,
        ).pop(true); // Retourner true pour indiquer le succès
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de l\'enregistrement: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _surfaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signaler un dépotoir')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    // Aperçu de la photo
                    GestureDetector(
                      onTap: _takePicture,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: _image == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text('Appuyez pour prendre une photo'),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.file(_image!, fit: BoxFit.cover),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Champ de saisie pour la surface
                    TextFormField(
                      controller: _surfaceController,
                      decoration: const InputDecoration(
                        labelText: 'Surface estimée (m²)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.square_foot),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une surface';
                        }
                        final surface = double.tryParse(value);
                        if (surface == null || surface <= 0) {
                          return 'Veuillez entrer une surface valide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Affichage des coordonnées GPS
                    if (_currentPosition != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Position actuelle:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                              ),
                              Text(
                                'Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Bouton de soumission
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text('Soumettre le signalement'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
