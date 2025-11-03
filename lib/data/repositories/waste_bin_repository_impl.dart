// import '../models/waste_bin.dart';
import '../services/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WasteBinRepository {
  final SupabaseClient _client = SupabaseClientService.instance.client;

  Future<List<dynamic>> getWasteBins() async {
    final data = await _client.from('waste_bins').select();
    return data;
  }

  // Future<void> addWasteBin(WasteBin wasteBin) async {
  //   await _client.from('waste_bins').insert(wasteBin.toJson());
  // }

  // Future<void> updateWasteBin(WasteBin wasteBin) async {
  //   await _client.from('waste_bins').update(wasteBin.toJson()).eq('id', wasteBin.id);
  // }

  // Future<void> deleteWasteBin(String id) async {
  //   await _client.from('waste_bins').delete().eq('id', id);
  // }
}
