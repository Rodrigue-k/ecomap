import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart' as latlong;

class WasteBin {
  final String id;
  final GeoPoint location; // Utiliser GeoPoint pour Firestore
  final DateTime createdAt;
  final String type;
  final String status;

  const WasteBin({
    required this.id,
    required this.location,
    required this.createdAt,
    this.type = 'general',
    this.status = 'available',
  });

  // Conversion vers latlong.LatLng
  latlong.LatLng get latLng =>
      latlong.LatLng(location.latitude, location.longitude);

  factory WasteBin.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WasteBin(
      id: doc.id,
      location: data['location'] as GeoPoint,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      type: data['type'] ?? 'general',
      status: data['status'] ?? 'available',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type,
      'status': status,
    };
  }
}
