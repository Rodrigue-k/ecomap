import 'dart:convert';

import 'package:ecomap/core/logger/app_logger.dart';
import 'package:ecomap/data/models/waste_dump_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class WasteDumpLocalDataSource {
  /// Récupère la liste des dépotoirs en cache
  Future<List<WasteDumpModel>> getCachedWasteDumps();

  /// Met en cache la liste des dépotoirs
  Future<void> cacheWasteDumps(List<WasteDumpModel> wasteDumps);

  /// Sauvegarde un dépotoir (ajoute ou met à jour)
  Future<void> saveWasteDump(WasteDumpModel wasteDump);

  /// Supprime un dépotoir du cache
  Future<void> deleteWasteDump(String id);

  /// Supprime tous les dépotoirs du cache
  Future<void> clearCache();
}

const String cachedWasteDumpsKey = 'CACHED_WASTE_DUMPS';

class WasteDumpLocalDataSourceImpl implements WasteDumpLocalDataSource {
  final SharedPreferences sharedPreferences;

  WasteDumpLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheWasteDumps(List<WasteDumpModel> wasteDumps) async {
    final jsonList = wasteDumps.map((e) => e.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await sharedPreferences.setString(cachedWasteDumpsKey, jsonString);
  }

  @override
  Future<List<WasteDumpModel>> getCachedWasteDumps() async {
    final jsonString = sharedPreferences.getString(cachedWasteDumpsKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((e) => WasteDumpModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      return [];
    }
  }

  @override
  Future<void> saveWasteDump(WasteDumpModel wasteDump) async {
    try {
      final wasteDumps = await getCachedWasteDumps();

      // Vérifier si le dépotoir existe déjà
      final index = wasteDumps.indexWhere((d) => d.id == wasteDump.id);

      if (index >= 0) {
        // Mise à jour
        wasteDumps[index] = wasteDump;
        AppLogger.d('Dépotoir mis à jour en cache: ${wasteDump.id}');
      } else {
        // Ajout
        wasteDumps.add(wasteDump);
        AppLogger.d('Nouveau dépotoir ajouté au cache: ${wasteDump.id}');
      }

      await cacheWasteDumps(wasteDumps);
    } catch (e, stackTrace) {
      AppLogger.e(
        'Erreur lors de la sauvegarde du dépotoir en cache',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteWasteDump(String id) async {
    try {
      final wasteDumps = await getCachedWasteDumps();
      wasteDumps.removeWhere((d) => d.id == id);
      await cacheWasteDumps(wasteDumps);
      AppLogger.d('Dépotoir supprimé du cache: $id');
    } catch (e, stackTrace) {
      AppLogger.e(
        'Erreur lors de la suppression du dépotoir du cache',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await sharedPreferences.remove(cachedWasteDumpsKey);
      AppLogger.d('Cache des dépotoirs vidé');
    } catch (e, stackTrace) {
      AppLogger.e(
        'Erreur lors de la suppression du cache',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
