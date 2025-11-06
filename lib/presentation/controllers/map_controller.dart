import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class MapController extends StateNotifier<MapState> {
  MapController() : super(const MapState());

  void updateLocation(LatLng location) {
    state = state.copyWith(currentLocation: location, status: MapStatus.ready);
  }

  void setError(String message) {
    state = state.copyWith(status: MapStatus.error, errorMessage: message);
  }
}

enum MapStatus { initial, loading, ready, error }

class MapState {
  final LatLng? currentLocation;
  final MapStatus status;
  final String? errorMessage;

  const MapState({
    this.currentLocation,
    this.status = MapStatus.initial,
    this.errorMessage,
  });

  List<Object?> get props => [currentLocation, status, errorMessage];

  MapState copyWith({
    LatLng? currentLocation,
    MapStatus? status,
    String? errorMessage,
  }) {
    return MapState(
      currentLocation: currentLocation ?? this.currentLocation,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final mapControllerProvider = StateNotifierProvider<MapController, MapState>(
  (ref) => MapController(),
);
