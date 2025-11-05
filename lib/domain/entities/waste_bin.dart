
import 'package:equatable/equatable.dart';

class WasteBin extends Equatable {
  final String id;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String deviceId;

  const WasteBin({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.deviceId,
  });

  factory WasteBin.fromJson(Map<String, dynamic> json) => WasteBin(
    id: json['id'] as String,
    latitude: json['lat'] as double,
    longitude: json['lng'] as double,
    imageUrl: json['photo_url'] as String,
    deviceId: json['device_id'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'lat': latitude,
    'lng': longitude,
    'photo_url': imageUrl,
    'device_id': deviceId,
  };

  @override
  List<Object?> get props => [id, latitude, longitude, imageUrl, deviceId];
}