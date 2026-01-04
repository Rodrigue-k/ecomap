// lib/presentation/widgets/waste_dump_details_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:ecomap/domain/entities/waste_dump.dart';
import 'package:url_launcher/url_launcher.dart';

class WasteDumpDetailsBottomSheet extends StatelessWidget {
  final WasteDump dump;
  const WasteDumpDetailsBottomSheet({super.key, required this.dump});

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _getStatusText(String status) {
    return switch (status.toLowerCase()) {
      'reported' => 'Signalé',
      'in_progress' => 'En cours',
      'resolved' => 'Résolu',
      _ => status,
    };
  }

  Widget _buildRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.9,
      padding: EdgeInsets.only(
        top: mediaQuery.padding.top + 16,
        bottom: mediaQuery.padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Détails du point de collecte', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Image
                  if (dump.photoUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(dump.photoUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
                    )
                  else
                    Container(height: 200, color: Colors.grey[200], child: const Icon(Icons.photo, size: 80, color: Colors.grey)),

                  const SizedBox(height: 16),

                  // Détails
                  _buildRow(Icons.calendar_today, 'Signalé le: ${_formatDate(dump.timestamp)}'),
                  _buildRow(Icons.square_foot, 'Surface: ${dump.surfaceArea.toStringAsFixed(1)} m²'),
                  _buildRow(Icons.info_outline, 'Statut: ${_getStatusText(dump.status)}'),
                  if (dump.reportedBy != null) _buildRow(Icons.person, 'Par: ${dump.reportedBy}'),
                  if (dump.tags?.isNotEmpty ?? false) _buildRow(Icons.tag, 'Tags: ${dump.tags!.join(', ')}'),
                  if (dump.description?.isNotEmpty ?? false) _buildRow(Icons.description, dump.description!),

                  const SizedBox(height: 24),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final lat = dump.latitude;
                      final lng = dump.longitude;
                      final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      } else {
                        // Gère l'erreur, e.g., show SnackBar
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Impossible d'ouvrir la carte")),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Je gère ce dépotoir', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}