import 'package:EcoMap/models/waste_bin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart' as latlong;

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection des poubelles
  static CollectionReference<Map<String, dynamic>> get _wasteBinsCollection =>
      _firestore.collection('waste_bins');

  // Récupérer toutes les poubelles
  static Stream<List<WasteBin>> getWasteBins() {
    return _wasteBinsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(WasteBin.fromFirestore).toList());
  }

  // Ajouter une nouvelle poubelle
  static Future<void> addWasteBin(latlong.LatLng location) async {
    try {
      await _wasteBinsCollection.add({
        'location': GeoPoint(location.latitude, location.longitude),
        'createdAt': Timestamp.now(),
        'type': 'general',
        'status': 'available',
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la poubelle: $e');
    }
  }

  // Mettre à jour une poubelle
  static Future<void> updateWasteBin(String id, Map<String, dynamic> updates) async {
    try {
      await _wasteBinsCollection.doc(id).update({
        ...updates,
        'lastUpdated': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  // Supprimer une poubelle
  static Future<void> deleteWasteBin(String id) async {
    try {
      await _wasteBinsCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }
}