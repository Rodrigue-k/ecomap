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

  @override
  List<Object?> get props => [id, latitude, longitude, imageUrl, deviceId];
}
