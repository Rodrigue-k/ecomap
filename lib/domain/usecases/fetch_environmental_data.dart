import '../../data/datasources/remote/open_meteo_api.dart';

class FetchEnvironmentalData {
  Future<Map<String, dynamic>?> call(double lat, double lon, {bool forAfrica = false}) async {
    return await OpenMeteoApi.fetch(lat, lon, forAfrica: forAfrica);
  }
}
