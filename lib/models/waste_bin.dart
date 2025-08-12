import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class WasteBin {
  final String id;
  final LatLng location;
  final DateTime createdAt;
  
  // Champs optionnels pour plus tard
  final String? name;
  final String? description;
  final String? type;
  final String? status;
  final String? addedBy;
  final DateTime? lastUpdated;
  final int? usageCount;

  WasteBin({
    required this.id,
    required this.location,
    required this.createdAt,
    this.name,
    this.description,
    this.type,
    this.status = 'available',
    this.addedBy,
    this.lastUpdated,
    this.usageCount = 0,
  });

  factory WasteBin.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final GeoPoint geoPoint = data['location'] as GeoPoint;
    
    return WasteBin(
      id: doc.id,
      location: LatLng(geoPoint.latitude, geoPoint.longitude),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      name: data['name'],
      description: data['description'],
      type: data['type'],
      status: data['status'],
      addedBy: data['addedBy'],
      lastUpdated: data['lastUpdated'] != null ? (data['lastUpdated'] as Timestamp).toDate() : null,
      usageCount: data['usageCount'],
    );
  }

  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'location': GeoPoint(location.latitude, location.longitude),
      'createdAt': Timestamp.fromDate(createdAt),
    };
    
    // Ajouter les champs optionnels seulement s'ils existent
    if (name != null && name!.isNotEmpty) data['name'] = name;
    if (description != null && description!.isNotEmpty) data['description'] = description;
    if (type != null && type!.isNotEmpty) data['type'] = type;
    if (status != null) data['status'] = status;
    if (addedBy != null && addedBy!.isNotEmpty) data['addedBy'] = addedBy;
    if (lastUpdated != null) data['lastUpdated'] = Timestamp.fromDate(lastUpdated!);
    if (usageCount != null) data['usageCount'] = usageCount;
    
    return data;
  }

  WasteBin copyWith({
    String? id,
    LatLng? location,
    DateTime? createdAt,
    String? name,
    String? description,
    String? type,
    String? status,
    String? addedBy,
    DateTime? lastUpdated,
    int? usageCount,
  }) {
    return WasteBin(
      id: id ?? this.id,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      addedBy: addedBy ?? this.addedBy,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      usageCount: usageCount ?? this.usageCount,
    );
  }
}
