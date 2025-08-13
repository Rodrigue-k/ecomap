import 'package:EcoMap/screens/add_bin/add_bin_controller.dart';
import 'package:EcoMap/screens/add_bin/widgets/location_loading.dart';
import 'package:EcoMap/screens/add_bin/widgets/location_not_obtained.dart';
import 'package:EcoMap/screens/add_bin/widgets/location_obtained.dart';
import 'package:flutter/material.dart';

class LocationCard extends StatelessWidget {
  final AddBinState state;
  final VoidCallback onGetLocation;
  final VoidCallback onAddBin;

  const LocationCard({
    super.key,
    required this.state,
    required this.onGetLocation,
    required this.onAddBin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (state.isLocationLoading) {
      return LocationLoadingWidget(message: state.locationProgressMessage);
    } else if (state.selectedLocation == null) {
      return LocationNotObtainedWidget(
        hasPermission: state.hasLocationPermission,
        onGetLocation: onGetLocation,
      );
    } else {
      return LocationObtainedWidget(
        location: state.selectedLocation!,
        accuracy: state.locationAccuracy,
        isLoading: state.isLoading,
        onAddBin: onAddBin,
      );
    }
  }
}