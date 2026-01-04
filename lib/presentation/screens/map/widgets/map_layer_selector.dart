import 'package:flutter/material.dart';

class MapLayerSelector extends StatelessWidget {
  final String selectedLayer;
  final Function(String) onLayerChanged;

  const MapLayerSelector({
    required this.selectedLayer,
    required this.onLayerChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final layers = [
      _LayerInfo('dépotoires', Icons.delete_outline, Colors.green),
      _LayerInfo('air', Icons.air, Colors.blue),
    ];

    return Container(
      height: 48.0,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: layers.asMap().entries.map((entry) {
          final layer = entry.value;
          final isActive = selectedLayer == layer.label;
          return Container(
            margin: EdgeInsets.only(
              right: entry.key < layers.length - 1 ? 6.0 : 0.0,
            ),
            child: Material(
              color: isActive ? layer.color : Colors.white,
              borderRadius: BorderRadius.circular(24.0),
              elevation: isActive ? 3.0 : 1.0,
              child: InkWell(
                borderRadius: BorderRadius.circular(24.0),
                onTap: () => onLayerChanged(layer.label),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        layer.icon,
                        size: 20.0,
                        color: isActive ? Colors.white : layer.color,
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        layer.label,
                        style: TextStyle(
                          fontSize: 14.0,
                          color: isActive ? Colors.white : Colors.black87,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LayerInfo {
  final String label;
  final IconData icon;
  final Color color;

  const _LayerInfo(this.label, this.icon, this.color);
  }
