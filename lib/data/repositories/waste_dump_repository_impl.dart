import 'package:ecomap/core/error/exceptions.dart';
import 'package:ecomap/core/error/failures.dart';
import 'package:ecomap/core/logger/app_logger.dart';
import 'package:ecomap/data/datasources/local/waste_dump_local_data_source.dart';
import 'package:ecomap/data/datasources/remote/waste_dump_remote_data_source.dart';
import 'package:ecomap/data/models/waste_dump_model.dart';
import 'package:ecomap/domain/entities/waste_dump.dart';
import 'package:ecomap/domain/repositories/waste_dump_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

class WasteDumpRepositoryImpl implements WasteDumpRepository {
  final WasteDumpLocalDataSource localDataSource;
  final WasteDumpRemoteDataSource remoteDataSource;

  WasteDumpRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<WasteDump>>> getWasteDumps() async {
    try {
      AppLogger.d('Récupération des dépotoirs depuis le serveur...');
      final remoteDumps = await remoteDataSource.getWasteDumps();

      AppLogger.d(
        '${remoteDumps.length} dépotoirs récupérés du serveur. Mise à jour du cache local...',
      );
      await localDataSource.cacheWasteDumps(remoteDumps);

      return Right(remoteDumps.map((e) => e.toEntity()).toList());
    } catch (e, stackTrace) {
      AppLogger.e(
        'Erreur lors de la récupération des dépotoirs distants. Tentative de récupération en cache...',
        error: e,
        stackTrace: stackTrace,
      );

      try {
        final localDumps = await localDataSource.getCachedWasteDumps();
        AppLogger.w('Utilisation de ${localDumps.length} dépotoirs en cache');
        return Right(localDumps.map((e) => e.toEntity()).toList());
      } catch (cacheError, cacheStack) {
        AppLogger.e(
          'Échec de la récupération des dépotoirs en cache',
          error: cacheError,
          stackTrace: cacheStack,
        );
        return Left(
          CacheFailure(message: 'Impossible de charger les dépotoirs'),
        );
      }
    }
  }

  @override
  Future<Either<Failure, WasteDump>> saveWasteDump(WasteDump wasteDump) async {
    // S'assurer que l'ID est défini
    final wasteDumpWithId = wasteDump.id.isEmpty
        ? wasteDump.copyWith(id: const Uuid().v4())
        : wasteDump;

    final model = WasteDumpModel.fromEntity(wasteDumpWithId);

    try {
      AppLogger.d('Sauvegarde locale du dépotoir: ${model.id}');
      await localDataSource.saveWasteDump(model);

      try {
        AppLogger.d('Synchronisation du dépotoir avec le serveur: ${model.id}');
        final savedModel = await remoteDataSource.saveWasteDump(model);
        AppLogger.i('Dépotoir synchronisé avec succès: ${model.id}');

        // Mettre à jour le cache local avec la réponse du serveur
        await localDataSource.saveWasteDump(savedModel);

        return Right(savedModel.toEntity());
      } on ServerException catch (e, stackTrace) {
        AppLogger.e(
          'Erreur lors de la synchronisation avec le serveur',
          error: e,
          stackTrace: stackTrace,
        );
        // On retourne quand même le modèle local malgré l'échec de synchronisation
        return Right(model.toEntity());
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'Échec de la sauvegarde du dépotoir',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure(message: 'Échec de la sauvegarde: $e'));
    }
  }

  @override
  Future<Either<Failure, WasteDump>> updateWasteDump(
    WasteDump wasteDump,
  ) async {
    if (wasteDump.id.isEmpty) {
      return Left(
        ServerFailure(
          message: 'Impossible de mettre à jour un dépotoir sans ID',
        ),
      );
    }

    final model = WasteDumpModel.fromEntity(wasteDump);

    try {
      AppLogger.d('Mise à jour locale du dépotoir: ${model.id}');
      await localDataSource.saveWasteDump(model);

      try {
        AppLogger.d('Mise à jour du dépotoir sur le serveur: ${model.id}');
        final updatedModel = await remoteDataSource.updateWasteDump(model);
        AppLogger.i('Dépotoir mis à jour avec succès: ${model.id}');

        // Mettre à jour le cache local avec la réponse du serveur
        await localDataSource.saveWasteDump(updatedModel);

        return Right(updatedModel.toEntity());
      } on ServerException catch (e, stackTrace) {
        AppLogger.e(
          'Erreur lors de la mise à jour sur le serveur',
          error: e,
          stackTrace: stackTrace,
        );
        // On retourne quand même le modèle local malgré l'échec de synchronisation
        return Right(model.toEntity());
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'Échec de la mise à jour du dépotoir',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure(message: 'Échec de la mise à jour: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteWasteDump(String id) async {
    if (id.isEmpty) {
      return Left(ServerFailure(message: 'ID de dépotoir invalide'));
    }

    try {
      AppLogger.d('Suppression locale du dépotoir: $id');
      await localDataSource.deleteWasteDump(id);

      try {
        AppLogger.d('Suppression du dépotoir sur le serveur: $id');
        await remoteDataSource.deleteWasteDump(id);
        AppLogger.i('Dépotoir supprimé avec succès: $id');
        return const Right(null);
      } on ServerException catch (e, stackTrace) {
        AppLogger.e(
          'Erreur lors de la suppression sur le serveur',
          error: e,
          stackTrace: stackTrace,
        );
        // On ne renvoie pas d'erreur pour ne pas perturber l'expérience utilisateur
        // La suppression locale a réussi, on considère que c'est un succès
        return const Right(null);
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'Échec de la suppression du dépotoir',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure(message: 'Échec de la suppression: $e'));
    }
  }

  @override
  Future<Either<Failure, WasteDump?>> getWasteDumpById(String id) async {
    if (id.isEmpty) {
      return Left(ServerFailure(message: 'ID de dépotoir invalide'));
    }

    try {
      // Essayer de récupérer depuis le serveur d'abord
      try {
        final remoteDumps = await remoteDataSource.getWasteDumps();
        final remoteDump = remoteDumps.firstWhere(
          (dump) => dump.id == id,
          orElse: () => throw Exception('Dépotoir non trouvé'),
        );

        // Mettre à jour le cache local
        await localDataSource.saveWasteDump(remoteDump);

        return Right(remoteDump.toEntity());
      } on ServerException catch (e, stackTrace) {
        AppLogger.w(
          'Impossible de récupérer le dépotoir depuis le serveur',
          error: e,
          stackTrace: stackTrace,
        );
        // Continuer avec la récupération locale en cas d'échec
      }

      // Récupérer depuis le cache local
      final localDumps = await localDataSource.getCachedWasteDumps();
      final localDump = localDumps.firstWhere(
        (dump) => dump.id == id,
        orElse: () => throw Exception('Dépotoir non trouvé en cache'),
      );

      return Right(localDump.toEntity());
    } on Exception catch (e, stackTrace) {
      AppLogger.e(
        'Échec de la récupération du dépotoir par ID',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure(message: 'Dépotoir non trouvé'));
    }
  }
}
