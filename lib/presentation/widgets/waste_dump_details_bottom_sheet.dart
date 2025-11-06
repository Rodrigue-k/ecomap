import 'package:ecomap/domain/entities/waste_dump.dart';
import 'package:flutter/material.dart';

class WasteDumpDetailsBottomSheet extends StatelessWidget {
  final WasteDump wasteDump;

  const WasteDumpDetailsBottomSheet({super.key, required this.wasteDump});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Waste Dump Details'));
  }
}
