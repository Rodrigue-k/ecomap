import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as lat_lng;
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:ecomap/domain/entities/air_quality_data.dart';

class AirQualityLayer extends ConsumerWidget {
  final List<AirQualityData> airQualityDataList;
  final bool isActive;
  final ValueChanged<AirQualityData>? onMarkerTap;
  final PopupController? popupController;

  const AirQualityLayer({
    super.key,
    required this.airQualityDataList,
    required this.isActive,
    this.onMarkerTap,
    this.popupController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isActive || airQualityDataList.isEmpty) {
      return const SizedBox.shrink();
    }

    return fm.MarkerLayer(
      markers: airQualityDataList.map((data) => fm.Marker(
        point: lat_lng.LatLng(data.latitude, data.longitude),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            onMarkerTap?.call(data);
          },
          child: _buildAirQualityMarker(data),
        ),
      )).toList(),
    );
  }

  Widget _buildAirQualityMarker(AirQualityData data) {
    // Determine color based on AQI (Air Quality Index)
    final aqi = data.aqi;
    final Color color;

    if (aqi <= 50) {
      color = Colors.green;
    } else if (aqi <= 100) {
      color = Colors.yellow;
    } else if (aqi <= 150) {
      color = Colors.orange;
    } else if (aqi <= 200) {
      color = Colors.red;
    } else if (aqi <= 300) {
      color = Colors.purple;
    } else {
      color = Colors.brown;
    }

    return Tooltip(
      message: data.statusText,
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha((0.7 * 255).round()),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.2 * 255).round()),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '${data.aqi}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
    ),
    );
  }
}

class AirQualityPopup extends StatelessWidget {
  final AirQualityData data;
  final VoidCallback onClose;

  const AirQualityPopup({
    super.key,
    required this.data,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Qualité de l\'air',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow('AQI', '${data.aqi}'),
            if (data.pm25 != null) _buildInfoRow('PM2.5', '${data.pm25!.toStringAsFixed(1)} µg/m³'),
            _buildInfoRow('Polluant principal', _getPollutantName(data.mainPollutant)),
            const Divider(),
            _buildInfoRow('Température', '${data.temperature.toStringAsFixed(1)}°C'),
            _buildInfoRow('Humidité', '${data.humidity.toStringAsFixed(1)}%'),
            _buildInfoRow('Pression', '${data.pressure.toStringAsFixed(1)} hPa'),
            const SizedBox(height: 8),
            Text(
              'Dernière mise à jour: ${_formatDateTime(data.timestamp)}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getPollutantName(String code) {
    switch (code.toLowerCase()) {
      case 'p2':
        return 'PM2.5';
      case 'p1':
        return 'PM10';
      case 'o3':
        return 'Ozone (O₃)';
      case 'n2':
        return 'Dioxyde d\'azote (NO₂)';
      case 's2':
        return 'Dioxyde de soufre (SO₂)';
      case 'co':
        return 'Monoxyde de carbone (CO)';
      default:
        return code;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
