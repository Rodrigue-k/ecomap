import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ecomap/domain/entities/air_quality_data.dart';
import 'package:logger/logger.dart';

class AirQualityService {
  final String apiKey;
  final http.Client client;
  final Logger _logger = Logger();

  AirQualityService(this.apiKey, {http.Client? client}) 
      : client = client ?? http.Client();

  /// Fetches air quality data for a specific city
  Future<AirQualityData?> fetchCityAirQuality({
    required String city,
    required String state,
    required String country,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.airvisual.com/v2/city?city=$city&state=$state&country=$country&key=$apiKey',
      );

      final response = await client.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Air quality API request timed out'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return AirQualityData.fromJson(json);
      } else {
        throw Exception('Failed to load air quality data: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error fetching air quality data: $e');
      rethrow;
    }
  }

  /// Fetches air quality data for specific coordinates (nearest station)
  Future<AirQualityData?> fetchNearestAirQuality({
    required double lat,
    required double lon,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.airvisual.com/v2/nearest_city?lat=$lat&lon=$lon&key=$apiKey',
      );

      final response = await client.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Air quality API request timed out'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return AirQualityData.fromJson(json);
      } else {
        throw Exception('Failed to load air quality data: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error fetching nearest air quality data: $e');
      rethrow;
    }
  }

  void dispose() {
    client.close();
  }
}
