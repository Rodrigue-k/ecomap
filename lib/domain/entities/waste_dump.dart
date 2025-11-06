import 'package:equatable/equatable.dart';

class WasteDump extends Equatable {
  final String id;
  final double latitude;
  final double longitude;
  final double surfaceArea; // en m²
  final String? photoUrl;
  final String status;
  final DateTime timestamp;
  final String? description;
  final List<String>? tags;
  final String? reportedBy;

  const WasteDump({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.surfaceArea,
    this.photoUrl,
    this.status = 'reported',
    required this.timestamp,
    this.description,
    this.tags,
    this.reportedBy,
  });

  @override
  List<Object?> get props => [
    id,
    latitude,
    longitude,
    surfaceArea,
    photoUrl,
    status,
    timestamp,
    description,
    tags,
    reportedBy,
  ];

  WasteDump copyWith({
    String? id,
    double? latitude,
    double? longitude,
    double? surfaceArea,
    String? photoUrl,
    String? status,
    DateTime? timestamp,
    String? description,
    List<String>? tags,
    String? reportedBy,
  }) {
    return WasteDump(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      surfaceArea: surfaceArea ?? this.surfaceArea,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      reportedBy: reportedBy ?? this.reportedBy,
    );
  }
}
