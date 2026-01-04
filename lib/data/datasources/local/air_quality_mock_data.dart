import 'package:ecomap/domain/entities/air_quality_data.dart';

final mockAirQualityDataAfrica = [
  // Bénin
  AirQualityData(
    latitude: 6.3725,  // Cotonou
    longitude: 2.3583,
    aqi: 65,
    mainPollutant: 'pm25',
    temperature: 28,
    humidity: 82,
    pressure: 1012,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  AirQualityData(
    latitude: 9.3077,  // Parakou
    longitude: 2.3158,
    aqi: 58,
    mainPollutant: 'pm10',
    temperature: 30,
    humidity: 75,
    pressure: 1011,
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  
  // Burkina Faso
  AirQualityData(
    latitude: 12.3657,  // Ouagadougou
    longitude: -1.5339,
    aqi: 85,
    mainPollutant: 'pm25',
    temperature: 32,
    humidity: 45,
    pressure: 1009,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  // Côte d'Ivoire
  AirQualityData(
    latitude: 5.3599,  // Abidjan
    longitude: -4.0083,
    aqi: 78,
    mainPollutant: 'pm25',
    temperature: 27,
    humidity: 83,
    pressure: 1010,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  // Sénégal
  AirQualityData(
    latitude: 14.6928,  // Dakar
    longitude: -17.4467,
    aqi: 72,
    mainPollutant: 'pm10',
    temperature: 26,
    humidity: 70,
    pressure: 1013,
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  
  // Mali
  AirQualityData(
    latitude: 12.6392,  // Bamako
    longitude: -7.9984,
    aqi: 92,
    mainPollutant: 'pm25',
    temperature: 34,
    humidity: 40,
    pressure: 1008,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  // Niger
  AirQualityData(
    latitude: 13.5127,  // Niamey
    longitude: 2.1125,
    aqi: 88,
    mainPollutant: 'pm10',
    temperature: 36,
    humidity: 35,
    pressure: 1007,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  // Togo
  AirQualityData(
    latitude: 6.1304,  // Lomé
    longitude: 1.2153,
    aqi: 68,
    mainPollutant: 'pm25',
    temperature: 29,
    humidity: 80,
    pressure: 1012,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  // Ghana
  AirQualityData(
    latitude: 5.5560,  // Accra
    longitude: -0.1969,
    aqi: 82,
    mainPollutant: 'pm25',
    temperature: 28,
    humidity: 78,
    pressure: 1011,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  AirQualityData(
    latitude: 6.6833,  // Kumasi
    longitude: -1.6167,
    aqi: 75,
    mainPollutant: 'pm10',
    temperature: 27,
    humidity: 76,
    pressure: 1012,
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  
  // Nigeria
  AirQualityData(
    latitude: 6.5244,  // Lagos
    longitude: 3.3792,
    aqi: 95,
    mainPollutant: 'pm25',
    temperature: 30,
    humidity: 82,
    pressure: 1010,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  AirQualityData(
    latitude: 9.0820,  // Abuja
    longitude: 7.4891,
    aqi: 88,
    mainPollutant: 'pm25',
    temperature: 31,
    humidity: 68,
    pressure: 1011,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  AirQualityData(
    latitude: 10.5105,  // Kano
    longitude: 7.4165,
    aqi: 102,
    mainPollutant: 'pm10',
    temperature: 33,
    humidity: 45,
    pressure: 1009,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  // Guinée
  AirQualityData(
    latitude: 9.6412,  // Conakry
    longitude: -13.5784,
    aqi: 65,
    mainPollutant: 'pm25',
    temperature: 28,
    humidity: 75,
    pressure: 1012,
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  
  // Sénégal (autres villes)
  AirQualityData(
    latitude: 14.6937,  // Thiès
    longitude: -16.4606,
    aqi: 68,
    mainPollutant: 'pm10',
    temperature: 27,
    humidity: 72,
    pressure: 1013,
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  
  AirQualityData(
    latitude: 16.0140,  // Saint-Louis
    longitude: -16.4896,
    aqi: 62,
    mainPollutant: 'pm10',
    temperature: 25,
    humidity: 68,
    pressure: 1014,
    timestamp: DateTime.now().subtract(const Duration(hours: 3)),
  ),
  
  // Côte d'Ivoire (autres villes)
  AirQualityData(
    latitude: 7.5400,  // Bouaké
    longitude: -5.5471,
    aqi: 72,
    mainPollutant: 'pm25',
    temperature: 29,
    humidity: 76,
    pressure: 1011,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  // Burkina Faso (autres villes)
  AirQualityData(
    latitude: 12.2383,  // Bobo-Dioulasso
    longitude: -4.2906,
    aqi: 80,
    mainPollutant: 'pm10',
    temperature: 33,
    humidity: 50,
    pressure: 1009,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  // Togo (autres villes)
  AirQualityData(
    latitude: 8.9833,  // Sokodé
    longitude: 1.1333,
    aqi: 70,
    mainPollutant: 'pm25',
    temperature: 30,
    humidity: 72,
    pressure: 1010,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  // Bénin (autres villes)
  AirQualityData(
    latitude: 7.1907,  // Porto-Novo
    longitude: 2.6042,
    aqi: 67,
    mainPollutant: 'pm25',
    temperature: 29,
    humidity: 80,
    pressure: 1011,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  // Niger (autres villes)
  AirQualityData(
    latitude: 13.8049,  // Zinder
    longitude: 8.9883,
    aqi: 84,
    mainPollutant: 'pm10',
    temperature: 35,
    humidity: 38,
    pressure: 1008,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  // Mali (autres villes)
  AirQualityData(
    latitude: 16.2667,  // Ségou
    longitude: -0.0500,
    aqi: 89,
    mainPollutant: 'pm25',
    temperature: 36,
    humidity: 42,
    pressure: 1007,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  AirQualityData(
    latitude: 14.5000,  // Mopti
    longitude: -4.2000,
    aqi: 91,
    mainPollutant: 'pm10',
    temperature: 35,
    humidity: 45,
    pressure: 1008,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  // Nigeria (autres villes)
  AirQualityData(
    latitude: 6.4531,  // Port Harcourt
    longitude: 3.3958,
    aqi: 98,
    mainPollutant: 'pm25',
    temperature: 29,
    humidity: 85,
    pressure: 1010,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  AirQualityData(
    latitude: 7.3964,  // Enugu
    longitude: 3.9167,
    aqi: 82,
    mainPollutant: 'pm25',
    temperature: 28,
    humidity: 80,
    pressure: 1011,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  // Ghana (autres villes)
  AirQualityData(
    latitude: 5.1167,  // Cape Coast
    longitude: -1.2500,
    aqi: 70,
    mainPollutant: 'pm10',
    temperature: 27,
    humidity: 82,
    pressure: 1012,
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  
  AirQualityData(
    latitude: 9.4333,  // Tamale
    longitude: -0.8500,
    aqi: 85,
    mainPollutant: 'pm25',
    temperature: 32,
    humidity: 55,
    pressure: 1009,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  // Guinée (autres villes)
  AirQualityData(
    latitude: 10.6500,  // Kankan
    longitude: -9.5000,
    aqi: 68,
    mainPollutant: 'pm25',
    temperature: 31,
    humidity: 60,
    pressure: 1010,
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  
  // Sénégal (autres villes)
  AirQualityData(
    latitude: 14.7903,  // Kaolack
    longitude: -16.9256,
    aqi: 72,
    mainPollutant: 'pm10',
    temperature: 30,
    humidity: 65,
    pressure: 1012,
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  
  AirQualityData(
    latitude: 13.4531,  // Ziguinchor
    longitude: -16.5775,
    aqi: 65,
    mainPollutant: 'pm25',
    temperature: 28,
    humidity: 75,
    pressure: 1013,
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  
  // Côte d'Ivoire (autres villes)
  AirQualityData(
    latitude: 7.6833,  // Daloa
    longitude: -6.6167,
    aqi: 75,
    mainPollutant: 'pm25',
    temperature: 28,
    humidity: 78,
    pressure: 1011,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  AirQualityData(
    latitude: 9.5500,  // Man
    longitude: -5.4833,
    aqi: 70,
    mainPollutant: 'pm10',
    temperature: 26,
    humidity: 80,
    pressure: 1012,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  // Togo (autres villes)
  AirQualityData(
    latitude: 6.9000,  // Kara
    longitude: 1.1000,
    aqi: 72,
    mainPollutant: 'pm25',
    temperature: 31,
    humidity: 65,
    pressure: 1010,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  
  // Bénin (autres villes)
  AirQualityData(
    latitude: 9.7000,  // Natitingou
    longitude: 1.6667,
    aqi: 68,
    mainPollutant: 'pm25',
    temperature: 29,
    humidity: 70,
    pressure: 1011,
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  ),
];
