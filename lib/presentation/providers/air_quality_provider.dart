import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecomap/core/services/air_quality_service.dart';
import 'package:ecomap/domain/entities/air_quality_data.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

// Provider for the AirQualityService
final airQualityServiceProvider = Provider<AirQualityService>((ref) {
  // Get API key from environment variables
  final apiKey = dotenv.get('AIR_VISUAL_API_KEY', fallback: '');
  if (apiKey.isEmpty) {
    throw Exception('AIR_VISUAL_API_KEY is not set in .env file');
  }
  return AirQualityService(apiKey);
});

// State for air quality data
class AirQualityState {
  final AirQualityData? data;
  final bool isLoading;
  final String? error;

  const AirQualityState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  AirQualityState copyWith({
    AirQualityData? data,
    bool? isLoading,
    String? error,
  }) {
    return AirQualityState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier for managing air quality state
class AirQualityNotifier extends StateNotifier<AirQualityState> {
  final Ref ref;
  
  AirQualityNotifier(this.ref) : super(const AirQualityState());

  // Get the service instance
  AirQualityService get _service => ref.read(airQualityServiceProvider);

  // Fetch air quality for a specific city
  Future<void> fetchCityAirQuality({
    required String city,
    required String stateParam,
    required String country,
  }) async {
    final currentState = state;
    state = AirQualityState(
      isLoading: true,
      error: null,
      data: currentState.data, // Preserve existing data
    );
    
    try {
      final data = await _service.fetchCityAirQuality(
        city: city,
        state: stateParam,
        country: country,
      );
      
      if (data != null) {
        state = AirQualityState(
          data: data,
          isLoading: false,
          error: null,
        );
      } else {
        state = AirQualityState(
          isLoading: false,
          error: 'No air quality data available',
          data: currentState.data, // Preserve existing data
        );
      }
    } catch (e) {
      state = AirQualityState(
        isLoading: false,
        error: 'Failed to fetch air quality data: $e',
        data: currentState.data, // Preserve existing data on error
      );
      rethrow;
    }
  }

  // Fetch air quality for specific coordinates
  Future<void> fetchNearestAirQuality(double lat, double lon) async {
    final currentState = state;
    state = AirQualityState(
      isLoading: true,
      error: null,
      data: currentState.data, // Preserve existing data
    );
    
    try {
      final data = await _service.fetchNearestAirQuality(lat: lat, lon: lon);
      
      if (data != null) {
        state = AirQualityState(
          data: data,
          isLoading: false,
          error: null,
        );
      } else {
        state = AirQualityState(
          isLoading: false,
          error: 'No air quality data available for this location',
          data: currentState.data, // Preserve existing data
        );
      }
    } catch (e) {
      state = AirQualityState(
        isLoading: false,
        error: 'Failed to fetch air quality data: $e',
        data: currentState.data, // Preserve existing data on error
      );
      rethrow;
    }
  }

  // Clear the current air quality data
  void clear() {
    state = const AirQualityState(
      data: null,
      isLoading: false,
      error: null,
    );
  }
}

// Provider for the AirQualityNotifier
final airQualityProvider = StateNotifierProvider<AirQualityNotifier, AirQualityState>((ref) {
  return AirQualityNotifier(ref);
});
