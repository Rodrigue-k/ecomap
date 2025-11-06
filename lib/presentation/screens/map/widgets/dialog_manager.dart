import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong;

class DialogManager {
  static Future<bool> showCustomDialog({
    required BuildContext context,
    required String title,
    required String content,
    required List<Widget> actions,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
        title: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          content,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: actions.map((action) {
          if (action is TextButton) {
            return TextButton(
              style: TextButton.styleFrom(
                foregroundColor:
                    action.style?.foregroundColor?.resolve({}) ??
                    Theme.of(context).colorScheme.primary,
                textStyle: Theme.of(context).textTheme.bodyLarge,
              ),
              onPressed: action.onPressed,
              child: action.child!,
            );
          }
          return action;
        }).toList(),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
    return result ?? false;
  }

  static Future<bool> showDeleteBinDialog(BuildContext context) {
    return showCustomDialog(
      context: context,
      title: 'Confirmer la suppression',
      content: 'Voulez-vous vraiment supprimer cette poubelle ?',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'Supprimer',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }

  static Future<bool> showAddBinDialog(
    BuildContext context,
    latlong.LatLng location,
  ) {
    return showCustomDialog(
      context: context,
      title: 'Ajouter une poubelle',
      content:
          'Ajouter une poubelle à votre position actuelle :\nLat: ${location.latitude.toStringAsFixed(6)}, Lon: ${location.longitude.toStringAsFixed(6)}',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
