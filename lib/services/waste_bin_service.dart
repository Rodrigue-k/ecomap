import 'package:EcoMap/models/waste_bin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class WasteBinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  Future<void> addWasteBin({required GeoPoint location}) async {
    try {
      final docRef = _firestore.collection('waste_bins').doc();
      await docRef.set({
        'location': location,
        'createdAt': Timestamp.now(),
        'status': 'active',
      });
      _logger.i('Bin added at ${location.latitude}, ${location.longitude}');
    } catch (e, stack) {
      _logger.e('Error adding bin', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Stream<List<WasteBin>> getWasteBins() {
    return _firestore.collection('waste_bins').snapshots().map((snapshot) {
      return snapshot.docs.map(WasteBin.fromFirestore).toList();
    });
  }
}