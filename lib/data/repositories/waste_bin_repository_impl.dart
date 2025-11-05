import 'package:uuid/uuid.dart';
import '../../domain/entities/waste_bin.dart';
import '../../domain/repositories/waste_bin_repository.dart';
import '../../core/services/device_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class WasteBinRepositoryImpl implements WasteBinRepository {
  final _client = Supabase.instance.client;

  @override
  Stream<List<WasteBin>> getWasteBins() {
    return _client
        .from('waste_bins')
        .stream(primaryKey: ['id'])
        .map((maps) => maps.map(WasteBin.fromJson).toList());
  }

  @override
  Future<void> addWasteBin({
    required double latitude,
    required double longitude,
    required String imageUrl,
  }) async {
    final deviceId = await DeviceService.instance.getDeviceId();
    if (deviceId == null) {
      throw Exception('Device ID not found');
    }

    final wasteBin = WasteBin(
      id: const Uuid().v4(),
      latitude: latitude,
      longitude: longitude,
      imageUrl: imageUrl,
      deviceId: deviceId,
    );

    await _client.from('waste_bins').insert(wasteBin.toJson());
  }

  @override
  Future<void> deleteWasteBin(String id) async {
    try {
      await _client
          .from('waste_bins')
          .delete()
          .eq('id', id);
    } catch (e) {
      debugPrint('Error deleting waste bin: $e');
      rethrow;
    }
  }
}

final wasteBinRepositoryProvider = Provider<WasteBinRepository>(
  (ref) => WasteBinRepositoryImpl(),
);
