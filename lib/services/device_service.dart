import '../core/app_logger.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  static const String _deviceIdKey = 'device_id';
  static String? _cachedDeviceId;

  // Récupère un identifiant unique pour l'appareil
  static Future<String?> getDeviceId() async {
    try {
      // Retourne l'ID en cache s'il existe
      if (_cachedDeviceId != null) return _cachedDeviceId!;

      final prefs = await SharedPreferences.getInstance();
      
      // Vérifie si un ID existe déjà dans les préférences partagées
      String? deviceId = prefs.getString(_deviceIdKey);
      
      if (deviceId == null) {
        // Génère un nouvel ID unique si aucun n'existe
        deviceId = await _generateDeviceId();
        if (deviceId != null) {
          await prefs.setString(_deviceIdKey, deviceId);
        }
      }
      
      _cachedDeviceId = deviceId;
      return deviceId;
    } catch (e) {
      AppLogger.e('Erreur lors de la récupération de l\'ID de l\'appareil: $e');
      return null;
    }
  }

  // Génère un ID d'appareil unique en utilisant les informations du matériel
  static Future<String?> _generateDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final info = await deviceInfo.deviceInfo;
      
      if (info is AndroidDeviceInfo) {
        return 'android-${info.id}';
      } else if (info is IosDeviceInfo) {
        return 'ios-${info.identifierForVendor ?? const Uuid().v4()}';
      } else if (info is WebBrowserInfo) {
        return 'web-${info.userAgent?.hashCode ?? const Uuid().v4()}';
      } else {
        // Pour les autres plateformes, on utilise un UUID aléatoire
        return 'unknown-${const Uuid().v4()}';
      }
    } catch (e) {
      AppLogger.e('Erreur lors de la génération de l\'ID de l\'appareil: $e');
      // En cas d'erreur, on retourne un UUID aléatoire
      return 'error-${const Uuid().v4()}';
    }
  }
}
