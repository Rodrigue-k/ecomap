// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
// import '../models/waste_bin.dart';
// import '../services/firebase_service.dart';
//
// class WasteBinInfoCard extends StatelessWidget {
//   final WasteBin wasteBin;
//   final VoidCallback? onClose;
//   final VoidCallback? onMarkAsUsed;
//
//   const WasteBinInfoCard({
//     super.key,
//     required this.wasteBin,
//     this.onClose,
//     this.onMarkAsUsed,
//   });
//
//   String _getTypeLabel(String type) {
//     switch (type) {
//       case 'general':
//         return 'Général';
//       case 'recyclable':
//         return 'Recyclable';
//       case 'organique':
//         return 'Organique';
//       case 'verre':
//         return 'Verre';
//       case 'papier':
//         return 'Papier';
//       case 'métal':
//         return 'Métal';
//       default:
//         return type;
//     }
//   }
//
//   String _getStatusLabel(String status) {
//     switch (status) {
//       case 'available':
//         return 'Disponible';
//       case 'full':
//         return 'Pleine';
//       case 'maintenance':
//         return 'En maintenance';
//       default:
//         return status;
//     }
//   }
//
//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'available':
//         return Colors.green;
//       case 'full':
//         return Colors.red;
//       case 'maintenance':
//         return Colors.orange;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   Color _getTypeColor(String type) {
//     switch (type) {
//       case 'general':
//         return Colors.blue;
//       case 'recyclable':
//         return Colors.green;
//       case 'organique':
//         return Colors.brown;
//       case 'verre':
//         return Colors.cyan;
//       case 'papier':
//         return Colors.yellow[700]!;
//       case 'métal':
//         return Colors.grey;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   Future<void> _navigateToBin() async {
//     final url = 'https://www.google.com/maps/dir/?api=1&destination=${wasteBin.location.latitude},${wasteBin.location.longitude}';
//
//     if (await canLaunchUrl(Uri.parse(url))) {
//       await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
//     } else {
//       throw 'Impossible d\'ouvrir Google Maps';
//     }
//   }
//
//   Future<void> _markAsUsed() async {
//     try {
//       await FirebaseService.markBinAsUsed(wasteBin.id);
//       if (onMarkAsUsed != null) {
//         onMarkAsUsed!();
//       }
//     } catch (e) {
//       // Gérer l'erreur
//       debugPrint('Erreur lors du marquage: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // En-tête avec bouton de fermeture
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: _getTypeColor(wasteBin.type!),
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(16),
//                 topRight: Radius.circular(16),
//               ),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   _getTypeIcon(wasteBin.type!),
//                   color: Colors.white,
//                   size: 24,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         wasteBin.name!,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Text(
//                         _getTypeLabel(wasteBin.type!),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 if (onClose != null)
//                   IconButton(
//                     onPressed: onClose,
//                     icon: const Icon(Icons.close, color: Colors.white),
//                     padding: EdgeInsets.zero,
//                     constraints: const BoxConstraints(),
//                   ),
//               ],
//             ),
//           ),
//
//           // Contenu principal
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Description
//                 if (wasteBin.description!.isNotEmpty) ...[
//                   Text(
//                     wasteBin.description!,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       height: 1.4,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                 ],
//
//                 // Statut et utilisation
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: _getStatusColor(wasteBin.status!).withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(color: _getStatusColor(wasteBin.status!)),
//                       ),
//                       child: Text(
//                         _getStatusLabel(wasteBin.status!),
//                         style: TextStyle(
//                           color: _getStatusColor(wasteBin.status!),
//                           fontSize: 12,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                     const Spacer(),
//                     Icon(Icons.people, size: 16, color: Colors.grey[600]),
//                     const SizedBox(width: 4),
//                     Text(
//                       '${wasteBin.usageCount} utilisations',
//                       style: TextStyle(
//                         color: Colors.grey[600],
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 const SizedBox(height: 16),
//
//                 // Date d'ajout
//                 Row(
//                   children: [
//                     Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
//                     const SizedBox(width: 8),
//                     Text(
//                       'Ajoutée le ${_formatDate(wasteBin.createdAt)}',
//                       style: TextStyle(
//                         color: Colors.grey[600],
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 const SizedBox(height: 20),
//
//                 // Boutons d'action
//                 Row(
//                   children: [
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: _navigateToBin,
//                         icon: const Icon(Icons.directions),
//                         label: const Text('Y aller'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: _markAsUsed,
//                         icon: const Icon(Icons.check),
//                         label: const Text('Utilisée'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   IconData _getTypeIcon(String type) {
//     switch (type) {
//       case 'general':
//         return Icons.delete;
//       case 'recyclable':
//         return Icons.recycling;
//       case 'organique':
//         return Icons.eco;
//       case 'verre':
//         return Icons.wine_bar;
//       case 'papier':
//         return Icons.article;
//       case 'métal':
//         return Icons.hardware;
//       default:
//         return Icons.delete;
//     }
//   }
//
//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year}';
//   }
// }
