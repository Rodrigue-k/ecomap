import 'package:flutter/material.dart';
import 'package:EcoMap/core/theme/app_theme.dart';

class CustomDialogs {
  // Affiche un dialogue personnalisé
  static Future<T?> showCustomDialog<T>({
    required BuildContext context,
    required String title,
    required String content,
    required List<Widget> actions,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => _buildCustomDialog(
        title: title,
        content: content,
        actions: actions,
      ),
    );
  }

  // Construit un dialogue personnalisé
  static Widget _buildCustomDialog({
    required String title,
    required String content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      content: Text(
        content,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 16,
        ),
      ),
      actions: actions.map((action) {
        if (action is TextButton) {
          return TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              textStyle: const TextStyle(fontSize: 16),
            ),
            onPressed: action.onPressed,
            child: action.child!,
          );
        }
        return action;
      }).toList(),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }

  // Affiche un dialogue de confirmation
  static Future<bool> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _buildCustomDialog(
        title: title,
        content: content,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: const TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
