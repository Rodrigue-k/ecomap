import 'package:EcoMap/models/waste_bin.dart';
import 'package:EcoMap/services/device_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:async';

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
      
      // Mettre à jour les statistiques de l'utilisateur
      await onWasteBinAdded();
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
      // Mettre à jour les statistiques de l'utilisateur
      await _incrementUserStat('deletedBins');
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  // Collection des statistiques utilisateur
  static CollectionReference<Map<String, dynamic>> get _userStatsCollection =>
      _firestore.collection('user_stats');

  // Incrémenter une statistique utilisateur
  static Future<void> _incrementUserStat(String statName) async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      if (deviceId == null) {
        print('Impossible d\'incrémenter la statistique: ID d\'appareil non disponible');
        return;
      }
      
      final docRef = _userStatsCollection.doc(deviceId);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (!doc.exists) {
          // Créer un nouveau document avec la statistique initialisée à 1
          transaction.set(docRef, {
            'deviceId': deviceId,
            statName: 1,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          // Incrémenter la statistique existante
          final currentValue = (doc.data()?[statName] as int?) ?? 0;
          transaction.update(docRef, {
            statName: currentValue + 1,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      print('Erreur lors de la mise à jour des statistiques utilisateur: $e');
    }
  }

  // Mettre à jour les statistiques lorsqu'une poubelle est ajoutée
  static Future<void> onWasteBinAdded() async {
    await _incrementUserStat('addedBins');
  }

  // Obtenir les statistiques de l'utilisateur actuel
  static Stream<Map<String, dynamic>> getUserStats() async* {
    final deviceId = await DeviceService.getDeviceId();
    if (deviceId == null) {
      yield {};
      return;
    }
    
    yield* _userStatsCollection
        .doc(deviceId)
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }
}