import 'package:fpdart/fpdart.dart';

import '../entities/waste_dump.dart';
import '../../core/error/failures.dart';

abstract class WasteDumpRepository {
  /// Récupère la liste des dépotoirs
  Future<Either<Failure, List<WasteDump>>> getWasteDumps();

  /// Enregistre un nouveau dépotoir
  Future<Either<Failure, WasteDump>> saveWasteDump(WasteDump wasteDump);

  /// Met à jour un dépotoir existant
  Future<Either<Failure, WasteDump>> updateWasteDump(WasteDump wasteDump);

  /// Supprime un dépotoir
  Future<Either<Failure, void>> deleteWasteDump(String id);

  /// Récupère un dépotoir par son ID
  Future<Either<Failure, WasteDump?>> getWasteDumpById(String id);
}
