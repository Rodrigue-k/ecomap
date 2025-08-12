import 'package:EcoMap/models/waste_bin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:latlong2/latlong.dart'
    as latlong2; // For explicit LatLng conversion

class WasteBinService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  static const String _collectionPath =
      'waste_bins'; // Ou le nom de votre collection

  // Récupère toutes les poubelles de la collection
  Stream<List<WasteBin>> getWasteBins() {
    _logger.i(
      'Attempting to get waste bins stream from Firestore: $_collectionPath',
    );
    return _firestore
        .collection(_collectionPath)
        .snapshots()
        .map<List<WasteBin>>((snapshot) {
          try {
            // Corrected to use WasteBin.fromFirestore(doc)
            final bins = snapshot.docs
                .map((doc) => WasteBin.fromFirestore(doc))
                .toList();
            _logger.i(
              'Successfully fetched and mapped ${bins.length} waste bins.',
            );
            return bins;
          } catch (e, stacktrace) {
            _logger.e(
              'Error mapping waste bins from Firestore',
              error: e,
              stackTrace: stacktrace,
            );
            return <WasteBin>[]; // Retourne une liste vide en cas d'erreur de mappage
          }
        })
        .handleError((error, stacktrace) {
          _logger.e(
            'Error fetching waste bins stream from Firestore',
            error: error,
            stackTrace: stacktrace,
          );
          return <WasteBin>[];
        });
  }

  // Ajoute une nouvelle poubelle à Firestore (version simplifiée)
  Future<DocumentReference?> addWasteBin({
    required latlong2.LatLng location,
    String? name,
    String? type,
    String? description,
    String? createdBy,
  }) async {
    _logger.i('Attempting to add new waste bin at $location');
    try {
      final newBin = WasteBin(
        id: '', // Firestore will generate this
        location: location,
        createdAt: DateTime.now(),
        name: name,
        type: type,
        description: description,
        addedBy: createdBy,
      );
      
      final docRef = await _firestore
          .collection(_collectionPath)
          .add(newBin.toFirestore());
      _logger.i('Successfully added new waste bin with ID: ${docRef.id}');
      return docRef;
    } catch (e, stacktrace) {
      _logger.e(
        'Error adding waste bin to Firestore',
        error: e,
        stackTrace: stacktrace,
      );
      return null;
    }
  }

  // Met à jour une poubelle existante (par exemple, marquer comme pleine/vide)
  Future<void> updateWasteBin(String binId, Map<String, dynamic> data) async {
    _logger.i('Attempting to update waste bin ID: $binId with data: $data');
    try {
      // Ensure lastUpdated is set on any update
      final Map<String, dynamic> updatedData = {
        ...data,
        'lastUpdated': Timestamp.now(),
      };
      await _firestore
          .collection(_collectionPath)
          .doc(binId)
          .update(updatedData);
      _logger.i('Successfully updated waste bin ID: $binId');
    } catch (e, stacktrace) {
      _logger.e(
        'Error updating waste bin ID: $binId',
        error: e,
        stackTrace: stacktrace,
      );
      // Gérer l'erreur comme il se doit
    }
  }

  // Vous pourriez ajouter d'autres méthodes utiles ici
  // Par exemple:
  // - getWasteBinById(String id)
  // - deleteWasteBin(String id)
  // - getBinsNearLocation(GeoPoint location, double radius)
}
