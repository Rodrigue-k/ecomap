import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecomap/core/logger/app_logger.dart';
import 'package:ecomap/domain/entities/waste_dump.dart';
import 'package:ecomap/core/providers/providers.dart';

final wasteDumpsProvider = FutureProvider.autoDispose<List<WasteDump>>((
  ref,
) async {
  final repository = ref.watch(wasteDumpRepositoryProvider);
  final result = await repository.getWasteDumps();

  return result.fold((failure) {
    // Logger l'erreur
    AppLogger.e(
      'Erreur lors du chargement des dépotoirs',
      error: failure,
      stackTrace: StackTrace.current,
    );
    return [];
  }, (wasteDumps) => wasteDumps);
});
