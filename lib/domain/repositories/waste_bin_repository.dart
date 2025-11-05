import '../entities/waste_bin.dart';

abstract class WasteBinRepository {
  Stream<List<WasteBin>> getWasteBins();
  Future<void> addWasteBin({
    required double latitude,
    required double longitude,
    required String imageUrl,
  });
  
  Future<void> deleteWasteBin(String id);
}
