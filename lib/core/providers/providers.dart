import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ecomap/domain/repositories/waste_dump_repository.dart';
import 'package:ecomap/domain/usecases/report_waste_dump_use_case.dart';
import 'package:ecomap/data/repositories/waste_dump_repository_impl.dart';
import 'package:ecomap/data/datasources/local/waste_dump_local_data_source.dart';
import 'package:ecomap/data/datasources/remote/waste_dump_remote_data_source.dart';

// Fournisseur pour SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

// Fournisseur pour la source de données locale
final wasteDumpLocalDataSourceProvider = Provider<WasteDumpLocalDataSource>((
  ref,
) {
  final sharedPrefs = ref.watch(sharedPreferencesProvider);
  return WasteDumpLocalDataSourceImpl(sharedPreferences: sharedPrefs);
});

// Fournisseur pour Supabase
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Fournisseur pour la source de données distante
final wasteDumpRemoteDataSourceProvider = Provider<WasteDumpRemoteDataSource>((
  ref,
) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return WasteDumpRemoteDataSourceImpl(supabaseClient: supabaseClient);
});

// Fournisseur pour le dépôt des dépotoirs
final wasteDumpRepositoryProvider = Provider<WasteDumpRepository>((ref) {
  final localDataSource = ref.watch(wasteDumpLocalDataSourceProvider);
  final remoteDataSource = ref.watch(wasteDumpRemoteDataSourceProvider);
  return WasteDumpRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
});

// Fournisseur pour le cas d'utilisation de signalement de dépotoir
final reportWasteDumpUseCaseProvider = Provider<ReportWasteDumpUseCase>((ref) {
  final repository = ref.watch(wasteDumpRepositoryProvider);
  return ReportWasteDumpUseCase(repository);
});
