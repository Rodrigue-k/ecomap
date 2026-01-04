import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenMeteoApi {
  static Future<Map<String, dynamic>?> fetch(double lat, double lon, {bool forAfrica = false}) async {
    Uri url;
    
    if (forAfrica) {
      // Coordonnées approximatives couvrant l'Afrique
      final north = 37.2;  // Nord de la Tunisie
      final south = -34.8; // Sud de l'Afrique du Sud
      final west = -17.5;  // Ouest du Sénégal
      final east = 51.4;   // Est de la Somalie
      
      // Créer une grille de points couvrant l'Afrique (réduite pour éviter trop de points)
      url = Uri.parse(
        'https://air-quality-api.open-meteo.com/v1/air-quality'
        '?latitude=$north,$south&longitude=$west,$east'
        '&hourly=pm2_5,pm10&current_weather=true',
      );
    } else {
      // Requête pour un point spécifique
      url = Uri.parse(
        'https://air-quality-api.open-meteo.com/v1/air-quality'
        '?latitude=$lat&longitude=$lon&hourly=pm10,pm2_5,temperature_2m,uv_index&current_weather=true',
      );
    }

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        print("❌ Erreur Open-Meteo: ${res.statusCode} - ${res.body}");
        return null;
      }
    } catch (e, stackTrace) {
      print("❌ Erreur de connexion à Open-Meteo: $e");
      print("Stack trace: $stackTrace");
      return null;
    }
  }
}
