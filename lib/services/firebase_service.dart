import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/waste_bin.dart';
import '../config/firebase_config.dart';
import 'package:latlong2/latlong.dart' as latlong2;

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection des poubelles
  static CollectionReference<Map<String, dynamic>> get _wasteBinsCollection =>
      _firestore.collection(FirebaseConfig.wasteBinsCollection);

  // Récupérer toutes les poubelles
  static Stream<List<WasteBin>> getWasteBins() {
    return _wasteBinsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WasteBin.fromFirestore(doc))
            .toList());
  }

  // Récupérer les poubelles dans un rayon donné
  static Stream<List<WasteBin>> getWasteBinsNearby(latlong2.LatLng center, double radiusKm) {
    // Note: Firestore ne supporte pas nativement les requêtes géospatiales
    // Cette implémentation récupère toutes les poubelles et filtre côté client
    // Pour une production, considérez utiliser GeoFirestore ou une solution similaire
    return _wasteBinsCollection
        .snapshots()
        .map((snapshot) {
          List<WasteBin> bins = snapshot.docs
              .map((doc) => WasteBin.fromFirestore(doc))
              .toList();
          
          // Filtrer par distance
          return bins.where((bin) {
            double distance = _calculateDistance(center, bin.location);
            return distance <= radiusKm;
          }).toList();
        });
  }

  // Ajouter une nouvelle poubelle
  static Future<String> addWasteBin(WasteBin wasteBin) async {
    try {
      DocumentReference docRef = await _wasteBinsCollection.add(wasteBin.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la poubelle: $e');
    }
  }

  // Mettre à jour une poubelle
  static Future<void> updateWasteBin(String id, Map<String, dynamic> updates) async {
    try {
      updates['lastUpdated'] = Timestamp.now();
      await _wasteBinsCollection.doc(id).update(updates);
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

  // Marquer une poubelle comme utilisée
  static Future<void> markBinAsUsed(String id) async {
    try {
      await _wasteBinsCollection.doc(id).update({
        'usageCount': FieldValue.increment(1),
        'lastUpdated': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  // Récupérer l'utilisateur actuel
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Calculer la distance entre deux points (formule de Haversine)
  static double _calculateDistance(latlong2.LatLng point1, latlong2.LatLng point2) {
    const double earthRadius = 6371; // Rayon de la Terre en km
    
    double lat1 = point1.latitude * (pi / 180);
    double lat2 = point2.latitude * (pi / 180);
    double deltaLat = (point2.latitude - point1.latitude) * (pi / 180);
    double deltaLon = (point2.longitude - point1.longitude) * (pi / 180);

    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }
}
