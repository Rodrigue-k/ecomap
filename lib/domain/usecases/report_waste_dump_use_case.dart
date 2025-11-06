import 'package:ecomap/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

import '../repositories/waste_dump_repository.dart';
import '../entities/waste_dump.dart';

class ReportWasteDumpUseCase {
  final WasteDumpRepository repository;

  const ReportWasteDumpUseCase(this.repository);

  Future<Either<Failure, void>> call(WasteDump wasteDump) async {
    return await repository.saveWasteDump(wasteDump);
  }
}
