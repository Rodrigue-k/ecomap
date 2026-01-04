import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecomap/data/datasources/local/air_quality_mock_data.dart';
import 'package:ecomap/domain/entities/air_quality_data.dart';

final airQualityMockProvider = Provider<List<AirQualityData>>((ref) {
  return mockAirQualityDataAfrica;
});

final airQualityMockStreamProvider = StreamProvider<List<AirQualityData>>((ref) async* {
  // Simule une mise à jour périodique des données
  while (true) {
    await Future.delayed(const Duration(minutes: 5));
    // Pour l'instant on retourne les mêmes données, mais on pourrait ajouter des variations
    yield mockAirQualityDataAfrica;
  }
});
