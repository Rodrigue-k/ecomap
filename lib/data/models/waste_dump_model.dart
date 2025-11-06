import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/waste_dump.dart';

class WasteDumpModel extends Equatable {
  final String id;
  final double latitude;
  final double longitude;
  final double surfaceArea;
  final String? photoUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? reportedBy;
  final String? description;
  final List<String>? tags;

  WasteDumpModel({
    String? id,
    required this.latitude,
    required this.longitude,
    required this.surfaceArea,
    this.photoUrl,
    this.status = 'reported',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.reportedBy,
    this.description,
    this.tags,
  }) : id = id ?? Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Convertir vers l'entité de domaine
  WasteDump toEntity() {
    return WasteDump(
      id: id,
      latitude: latitude,
      longitude: longitude,
      surfaceArea: surfaceArea,
      photoUrl: photoUrl,
      status: status,
      timestamp: createdAt,
      description: description,
      tags: tags,
    );
  }

  // Créer un modèle à partir d'une entité
  factory WasteDumpModel.fromEntity(WasteDump entity) {
    return WasteDumpModel(
      id: entity.id,
      latitude: entity.latitude,
      longitude: entity.longitude,
      surfaceArea: entity.surfaceArea,
      photoUrl: entity.photoUrl,
      status: entity.status,
      description: entity.description,
      tags: entity.tags,
    );
  }

  // Depuis JSON
  factory WasteDumpModel.fromJson(Map<String, dynamic> json) {
    return WasteDumpModel(
      id: json['id'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      surfaceArea: (json['surface_area'] as num).toDouble(),
      photoUrl: json['photo_url'] as String?,
      status: json['status'] as String? ?? 'reported',
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'] as String)
          : (json['created_at'] as DateTime?),
      updatedAt: json['updated_at'] is String
          ? DateTime.parse(json['updated_at'] as String)
          : (json['updated_at'] as DateTime?),
      reportedBy: json['reported_by'] as String?,
      description: json['description'] as String?,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : null,
    );
  }

  // Vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'surface_area': surfaceArea,
      'photo_url': photoUrl,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (reportedBy != null) 'reported_by': reportedBy,
      if (description != null) 'description': description,
      if (tags != null) 'tags': tags,
    };
  }

  @override
  List<Object?> get props => [
    id,
    latitude,
    longitude,
    surfaceArea,
    photoUrl,
    status,
    createdAt,
    updatedAt,
    reportedBy,
    description,
    tags,
  ];
}
