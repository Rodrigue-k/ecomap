
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart' as heatmap;
import 'package:latlong2/latlong.dart' as lat_lng;
import 'package:ecomap/core/logger/app_logger.dart';
import '../../../../domain/usecases/fetch_environmental_data.dart';

class AirQualityData {
  final double latitude;
  final double longitude;
  final double? pm25;
  final double? pm10;
  final double? temperature;
  final DateTime? lastUpdated;
  final bool isLoading;
  final String? error;
  final bool isAfricaData;
  final List<Map<String, dynamic>>? points; // Pour stocker plusieurs points de données pour l'Afrique

  AirQualityData({
    required this.latitude,
    required this.longitude,
    this.pm25,
    this.pm10,
    this.temperature,
    this.lastUpdated,
    this.isLoading = false,
    this.error,
    this.isAfricaData = false,
    this.points,
  });

  AirQualityData copyWith({
    double? latitude,
    double? longitude,
    double? pm25,
    double? pm10,
    double? temperature,
    DateTime? lastUpdated,
    bool? isLoading,
    String? error,
    bool? isAfricaData,
    List<Map<String, dynamic>>? points,
  }) {
    return AirQualityData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      pm25: pm25 ?? this.pm25,
      pm10: pm10 ?? this.pm10,
      temperature: temperature ?? this.temperature,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAfricaData: isAfricaData ?? this.isAfricaData,
      points: points ?? this.points,
    );
  }

  // Convertit les données brutes de l'API en un format utilisable
  factory AirQualityData.fromApiResponse(Map<String, dynamic> data, double lat, double lon) {
    try {
      // Vérifier si c'est une réponse pour l'Afrique (avec plusieurs points)
      if (data.containsKey('latitude') && data['latitude'] is List) {
        // C'est une réponse pour l'Afrique avec plusieurs points
        final lats = data['latitude'] as List<dynamic>;
        final lons = data['longitude'] as List<dynamic>;
        final pm25Data = data['hourly']?['pm2_5'] as List<dynamic>?;
        final pm10Data = data['hourly']?['pm10'] as List<dynamic>?;
        
        if (lats.isEmpty || lons.isEmpty || pm25Data == null || pm10Data == null) {
          return AirQualityData(
            latitude: lat,
            longitude: lon,
            isAfricaData: true,
            error: 'Données de qualité de l\'air pour l\'Afrique incomplètes',
          );
        }
        
        // Créer une liste de points avec les données de qualité de l'air
        final points = <Map<String, dynamic>>[];
        for (int i = 0; i < lats.length; i++) {
          final pointLat = (lats[i] as num).toDouble();
          final pointLon = (lons[i] as num).toDouble();
          final pm25 = pm25Data.isNotEmpty ? (pm25Data[i] as num?)?.toDouble() : null;
          final pm10 = pm10Data.isNotEmpty ? (pm10Data[i] as num?)?.toDouble() : null;
          
          points.add({
            'latitude': pointLat,
            'longitude': pointLon,
            'pm25': pm25,
            'pm10': pm10,
          });
        }
        
        return AirQualityData(
          latitude: lat,
          longitude: lon,
          isAfricaData: true,
          points: points,
          lastUpdated: DateTime.now(),
        );
      } else {
        // C'est une réponse pour un point unique
        final hourly = data['hourly'] as Map<String, dynamic>?;
        if (hourly == null || !hourly.containsKey('time') || !hourly.containsKey('pm2_5') || !hourly.containsKey('pm10')) {
          return AirQualityData(latitude: lat, longitude: lon, error: 'Données de qualité de l\'air incomplètes');
        }

        final times = hourly['time'] as List<dynamic>;
        if (times.isEmpty) {
          return AirQualityData(latitude: lat, longitude: lon, error: 'Aucune donnée temporelle disponible');
        }

        // Prendre la dernière valeur disponible (la plus récente)
        final lastIndex = times.length - 1;
        
        // Gestion des différents types de données pour le timestamp
        int timestamp;
        if (times[lastIndex] is int) {
          timestamp = times[lastIndex] as int;
        } else if (times[lastIndex] is String) {
          // Essayer de parser la chaîne en timestamp
          final dateTime = DateTime.tryParse(times[lastIndex] as String);
          timestamp = dateTime!.millisecondsSinceEpoch ~/ 1000;
        } else {
          timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        }

        // Gestion des valeurs PM2.5 et PM10
        final pm25List = hourly['pm2_5'] as List<dynamic>;
        final pm10List = hourly['pm10'] as List<dynamic>;
        
        if (pm25List.isEmpty || pm10List.isEmpty) {
          return AirQualityData(latitude: lat, longitude: lon, error: 'Données de qualité de l\'air manquantes');
        }

        // Prendre la dernière valeur disponible pour PM2.5 et PM10
        final pm25 = (pm25List[lastIndex] as num?)?.toDouble();
        final pm10 = (pm10List[lastIndex] as num?)?.toDouble();

        // Récupérer la température si disponible
        double? temp;
        if (hourly.containsKey('temperature_2m')) {
          final tempList = hourly['temperature_2m'] as List<dynamic>;
          if (tempList.isNotEmpty) {
            temp = (tempList[lastIndex] as num?)?.toDouble();
          }
        }

        return AirQualityData(
          latitude: lat,
          longitude: lon,
          pm25: pm25,
          pm10: pm10,
          temperature: temp,
          lastUpdated: DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
          isAfricaData: false,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.e('Erreur lors de la conversion des données de qualité de l\'air', 
                 error: e, 
                 stackTrace: stackTrace);
      return AirQualityData(
        latitude: lat,
        longitude: lon,
        error: 'Erreur lors du traitement des données: $e',
        isAfricaData: false,
      );
    }
  }
}

class MapState {
  final String selectedLayer;
  final AirQualityData? airQualityData;
  final bool isLoading;
  final String? error;

  MapState({
    this.selectedLayer = 'dépotoires',
    this.airQualityData,
    this.isLoading = false,
    this.error,
  });

  MapState copyWith({
    String? selectedLayer,
    AirQualityData? airQualityData,
    bool? isLoading,
    String? error,
  }) {
    return MapState(
      selectedLayer: selectedLayer ?? this.selectedLayer,
      airQualityData: airQualityData ?? this.airQualityData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final mapControllerProvider = StateNotifierProvider<MapController, MapState>((ref) {
  return MapController();
});

class MapController extends StateNotifier<MapState> {
  final _fetchData = FetchEnvironmentalData();
  
  MapController() : super(MapState());

  void changeLayer(String layer) {
    AppLogger.d('Changement de couche: $layer');
    state = state.copyWith(selectedLayer: layer);
    AppLogger.d('Nouvelle couche sélectionnée: ${state.selectedLayer}');
  }

  Future<void> loadAirQualityData(double lat, double lon, {bool forAfrica = false}) async {
    AppLogger.d('Chargement des données de qualité de l\'air ${forAfrica ? 'pour l\'Afrique' : ''} pour lat: $lat, lon: $lon');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      Map<String, dynamic> data;
      
      if (forAfrica) {
        // Utiliser des données simulées pour l'Afrique
        AppLogger.d('Génération de données simulées pour l\'Afrique...');
        data = _generateMockAfricaAirQualityData();
        AppLogger.i('Données simulées générées avec succès');
      } else {
        // Utiliser l'API pour les données normales
        AppLogger.d('Appel de l\'API Open-Meteo...');
        final apiData = await _fetchData(lat, lon);
        if (apiData == null) {
          throw Exception('Impossible de récupérer les données de l\'API');
        }
        data = apiData;
      }
      
      // Traiter les données récupérées
      AppLogger.i('Données de qualité de l\'air ${forAfrica ? 'simulées ' : ''}récupérées avec succès');
      final airQualityData = AirQualityData.fromApiResponse(data, lat, lon);
      state = state.copyWith(
        airQualityData: airQualityData,
        isLoading: false,
        selectedLayer: 'air', // S'assurer que la couche air est sélectionnée
      );
      AppLogger.d('Données mises à jour dans l\'état: ${airQualityData.toString()}');
    } catch (e, stackTrace) {
      final errorMsg = 'Erreur lors du chargement des données de qualité de l\'air: $e';
      AppLogger.e(errorMsg, error: e, stackTrace: stackTrace);
      state = state.copyWith(
        error: errorMsg,
        isLoading: false,
      );
      rethrow;
    }
  }

  // Méthode pour générer des points de chaleur pour la qualité de l'air
  List<heatmap.WeightedLatLng> generateAirQualityHeatmapPoints() {
    final points = <heatmap.WeightedLatLng>[];
    final data = state.airQualityData;
    if (data == null) return points;

    // Si on a des données pour l'Afrique (plusieurs points)
    if (data.isAfricaData && data.points != null) {
      // Convertir les points de données en WeightedLatLng
      for (final point in data.points!) {
        final lat = point['latitude'] as double;
        final lng = point['longitude'] as double;
        final pm25 = (point['pm25'] as num?)?.toDouble() ?? 0.0;
        
        points.add(heatmap.WeightedLatLng(
          lat_lng.LatLng(lat, lng),
          pm25.clamp(0, 100).toDouble(),
        ));
      }
    } 
    // Données pour un point unique
    else if (data.pm25 != null) {
points.add(heatmap.WeightedLatLng(
        lat_lng.LatLng(data.latitude, data.longitude),
        data.pm25!.clamp(0, 100).toDouble(),
      ));
    }
    
    return points;
  }
  
  // Génère des données simulées pour la qualité de l'air en Afrique
  Map<String, dynamic> _generateMockAfricaAirQualityData() {
    // Coordonnées approximatives des limites de l'Afrique
    const double minLat = -35.0;  // Cap de Bonne-Espérance, Afrique du Sud
    const double maxLat = 37.0;   // Côte méditerranéenne
    const double minLon = -18.0;  // Cap Vert
    const double maxLon = 52.0;   // Corne de l'Afrique
    
    // Créer une grille de points couvrant l'Afrique
    final List<Map<String, dynamic>> points = [];
    final Random random = Random();
    
    // Générer environ 100 points répartis sur le continent
    for (int i = 0; i < 100; i++) {
      // Générer des coordonnées aléatoires dans les limites de l'Afrique
      final lat = minLat + (maxLat - minLat) * random.nextDouble();
      final lng = minLon + (maxLon - minLon) * random.nextDouble();
      
      // Générer des valeurs de PM2.5 réalistes (0-200 µg/m³)
      // avec des zones plus polluées dans les régions urbaines d'Afrique du Nord et d'Afrique du Sud
      double basePm25;
      
      // Zones urbaines plus polluées
      bool isUrbanArea = random.nextDouble() < 0.3; // 30% de chance d'être dans une zone urbaine
      
      if (isUrbanArea) {
        // Zones urbaines d'Afrique du Nord (pollution plus élevée)
        if (lat > 20.0 && lat < 35.0 && lng > -10.0 && lng < 30.0) {
          basePm25 = 60.0 + random.nextDouble() * 80.0; // 60-140 µg/m³
        }
        // Zones urbaines d'Afrique du Sud (pollution modérée)
        else if (lat < -20.0 && lat > -35.0 && lng > 15.0 && lng < 35.0) {
          basePm25 = 40.0 + random.nextDouble() * 60.0; // 40-100 µg/m³
        }
        // Autres zones urbaines
        else {
          basePm25 = 30.0 + random.nextDouble() * 50.0; // 30-80 µg/m³
        }
      } else {
        // Zones rurales (moins polluées)
        basePm25 = 5.0 + random.nextDouble() * 25.0; // 5-30 µg/m³
      }
      
      // Ajouter de la variabilité aléatoire
      final pm25 = (basePm25 * (0.8 + 0.4 * random.nextDouble())).roundToDouble();
      final pm10 = (pm25 * (1.2 + 0.6 * random.nextDouble())).roundToDouble();
      
      points.add({
        'latitude': lat,
        'longitude': lng,
        'pm25': pm25,
        'pm10': pm10,
      });
    }
    
    return {
      'latitude': 2.0,  // Position centrale de l'Afrique
      'longitude': 17.0,
      'hourly': {
        'pm2_5': points.map((p) => p['pm25']).toList(),
        'pm10': points.map((p) => p['pm10']).toList(),
      },
      'points': points,
    };
  }

  // Méthode pour obtenir la légende de la qualité de l'air
  List<Map<String, dynamic>> getAirQualityLegend() {
    return [
      {
        'color': const Color(0xFF00E400), // Vert
        'label': 'Bonne',
        'range': '0-12',
        'description': '0-12 µg/m³ - Qualité de l\'air satisfaisante',
      },
      {
        'color': const Color(0xFFFFD700), // Jaune or (plus visible)
        'label': 'Modérée',
        'range': '12-35',
        'description': '12-35 µg/m³ - Qualité de l\'air acceptable',
      },
      {
        'color': const Color(0xFFFF8C00), // Orange foncé (plus visible)
        'label': 'Mauvaise',
        'range': '35-55',
        'description': '35-55 µg/m³ - Risque pour les personnes sensibles',
      },
      {
        'color': const Color(0xFFFF0000), // Rouge
        'label': 'Très mauvaise',
        'range': '55-150',
        'description': '55-150 µg/m³ - Effets sur la santé pour tous',
      },
      {
        'color': const Color(0xFF8B008B), // Violet foncé (plus lisible)
        'label': 'Dangereuse',
        'range': '150+',
        'description': '150+ µg/m³ - Urgence sanitaire',
      },
    ];
  }
}


