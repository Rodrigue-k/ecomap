import 'package:equatable/equatable.dart';

class AirQualityData extends Equatable {
  final double latitude;
  final double longitude;
  final int aqi;
  final double? pm25;
  final String mainPollutant;
  final double temperature;
  final double humidity;
  final double pressure;
  final DateTime timestamp;
  final String? status;

  /// Returns the air quality status based on AQI value
  String get statusText {
    if (aqi <= 50) return 'Bon';
    if (aqi <= 100) return 'Modéré';
    if (aqi <= 150) return 'Malsain pour les groupes sensibles';
    if (aqi <= 200) return 'Malsain';
    if (aqi <= 300) return 'Très malsain';
    return 'Dangereux';
  }

  AirQualityData({
    required this.latitude,
    required this.longitude,
    required this.aqi,
    this.pm25,
    required this.mainPollutant,
    required this.temperature,
    required this.humidity,
    required this.pressure,
    DateTime? timestamp,
    this.status,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        aqi,
        pm25,
        mainPollutant,
        temperature,
        humidity,
        pressure,
        timestamp,
        status,
      ];

  AirQualityData copyWith({
    double? latitude,
    double? longitude,
    int? aqi,
    double? pm25,
    String? mainPollutant,
    double? temperature,
    double? humidity,
    double? pressure,
    DateTime? timestamp,
  }) {
    return AirQualityData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      aqi: aqi ?? this.aqi,
      pm25: pm25 ?? this.pm25,
      mainPollutant: mainPollutant ?? this.mainPollutant,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      pressure: pressure ?? this.pressure,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    final loc = json['data']['location']['coordinates'];
    final pollution = json['data']['current']['pollution'];
    final weather = json['data']['current']['weather'];

    return AirQualityData(
      latitude: (loc?[1] as num?)?.toDouble() ?? 0.0,
      longitude: (loc?[0] as num?)?.toDouble() ?? 0.0,
      aqi: (pollution?['aqius'] as num?)?.toInt() ?? 0,
      pm25: (pollution?['aqicn'] as num?)?.toDouble(),
      mainPollutant: pollution?['mainus']?.toString() ?? 'p2',
      temperature: (weather?['tp'] as num?)?.toDouble() ?? 0.0,
      humidity: (weather?['hu'] as num?)?.toDouble() ?? 0.0,
      pressure: (weather?['pr'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
