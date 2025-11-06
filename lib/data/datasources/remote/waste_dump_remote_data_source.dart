import 'package:ecomap/core/error/exceptions.dart';
import 'package:ecomap/core/logger/app_logger.dart';
import 'package:ecomap/data/models/waste_dump_model.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class WasteDumpRemoteDataSource {
  /// Récupère tous les dépotoirs depuis Supabase
  Future<List<WasteDumpModel>> getWasteDumps();

  /// Sauvegarde un nouveau dépotoir sur Supabase
  Future<WasteDumpModel> saveWasteDump(WasteDumpModel wasteDump);

  /// Met à jour un dépotoir existant
  Future<WasteDumpModel> updateWasteDump(WasteDumpModel wasteDump);

  /// Supprime un dépotoir
  Future<void> deleteWasteDump(String id);
}

class WasteDumpRemoteDataSourceImpl implements WasteDumpRemoteDataSource {
  final SupabaseClient supabaseClient;

  WasteDumpRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<WasteDumpModel>> getWasteDumps() async {
    try {
      AppLogger.d('Récupération des dépotoirs depuis Supabase');

      final response = await supabaseClient
          .from('waste_dumps')
          .select()
          .order('created_at', ascending: false);

      if (response == []) {
        throw ServerException('Aucune donnée reçue du serveur');
      }

      return (response as List)
          .map((json) => WasteDumpModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e, stackTrace) {
      AppLogger.e(
        'Erreur Postgrest lors de la récupération des dépotoirs',
        error: e,
        stackTrace: stackTrace,
      );
      throw ServerException(e.message);
    } catch (e, stackTrace) {
      AppLogger.e(
        'Erreur inattendue lors de la récupération des dépotoirs',
        error: e,
        stackTrace: stackTrace,
      );
      throw ServerException('Erreur lors de la récupération des dépotoirs');
    }
  }

  /// Téléverse une image vers le stockage Supabase et retourne l'URL publique
  Future<String?> _uploadImage(String filePath) async {
    try {
      if (filePath.isEmpty) return null;

      final file = File(filePath);
      if (!await file.exists()) {
        AppLogger.w('Le fichier image n\'existe pas: $filePath');
        return null;
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(filePath)}';
      final fileBytes = await file.readAsBytes();

      await supabaseClient.storage
          .from('waste_photos')
          .uploadBinary(fileName, fileBytes);

      // Récupérer l'URL publique de l'image
      final response = supabaseClient.storage
          .from('waste_photos')
          .getPublicUrl(fileName);

      return response;
    } catch (e, stackTrace) {
      AppLogger.e(
        'Erreur lors du téléversement de l\'image',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<WasteDumpModel> saveWasteDump(WasteDumpModel wasteDump) async {
    try {
      AppLogger.d('Sauvegarde d\'un nouveau dépotoir: ${wasteDump.id}');

      // Téléverser l'image si nécessaire
      String? photoUrl = wasteDump.photoUrl;
      if (photoUrl != null && photoUrl.startsWith('/')) {
        photoUrl = await _uploadImage(photoUrl);
      }

      // Mettre à jour l'URL de la photo si elle a été téléversée
      final data = wasteDump.toJson()
        ..remove('id')
        ..['photo_url'] = photoUrl;

      final response = await supabaseClient
          .from('waste_dumps')
          .insert(data)
          .select()
          .single();

      return WasteDumpModel.fromJson(response);
    } on PostgrestException catch (e, stackTrace) {
      AppLogger.e(
        'Erreur Postgrest lors de la sauvegarde du dépotoir',
        error: e,
        stackTrace: stackTrace,
      );
      throw ServerException(e.message);
    } catch (e, stackTrace) {
      AppLogger.e(
        'Erreur inattendue lors de la sauvegarde du dépotoir',
        error: e,
        stackTrace: stackTrace,
      );
      throw ServerException('Erreur lors de la sauvegarde du dépotoir: $e');
    }
  }

  @override
  Future<WasteDumpModel> updateWasteDump(WasteDumpModel wasteDump) async {
    try {
      AppLogger.d('Mise à jour du dépotoir: ${wasteDump.id}');

      final data = wasteDump.toJson()..remove('id');

      final response = await supabaseClient
          .from('waste_dumps')
          .update(data)
          .eq('id', wasteDump.id)
          .select()
          .single();

      return WasteDumpModel.fromJson(response);
    } on PostgrestException catch (e, stackTrace) {
      AppLogger.e(
        'Erreur Postgrest lors de la mise à jour du dépotoir',
        error: e,
        stackTrace: stackTrace,
      );
      throw ServerException(e.message);
    } catch (e, stackTrace) {
      AppLogger.e(
        'Erreur inattendue lors de la mise à jour du dépotoir',
        error: e,
        stackTrace: stackTrace,
      );
      throw ServerException('Erreur lors de la mise à jour du dépotoir: $e');
    }
  }

  @override
  Future<void> deleteWasteDump(String id) async {
    try {
      AppLogger.d('Suppression du dépotoir: $id');

      await supabaseClient.from('waste_dumps').delete().eq('id', id);
    } on PostgrestException catch (e, stackTrace) {
      AppLogger.e(
        'Erreur Postgrest lors de la suppression du dépotoir',
        error: e,
        stackTrace: stackTrace,
      );
      throw ServerException(e.message);
    } catch (e, stackTrace) {
      AppLogger.e(
        'Erreur inattendue lors de la suppression du dépotoir',
        error: e,
        stackTrace: stackTrace,
      );
      throw ServerException('Erreur lors de la suppression du dépotoir: $e');
    }
  }
}
