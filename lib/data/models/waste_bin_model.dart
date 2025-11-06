import 'package:ecomap/domain/entities/waste_bin.dart';

class WasteBinModel extends WasteBin {
  const WasteBinModel({
    required super.id,
    required super.latitude,
    required super.longitude,
    required super.imageUrl,
    required super.deviceId,
  });

  factory WasteBinModel.fromJson(Map<String, dynamic> json) {
    return WasteBinModel(
      id: json['id'] as String,
      latitude: json['lat'] as double,
      longitude: json['lng'] as double,
      imageUrl: json['photo_url'] as String,
      deviceId: json['device_id'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lat': latitude,
      'lng': longitude,
      'photo_url': imageUrl,
      'device_id': deviceId,
    };
  }
}
