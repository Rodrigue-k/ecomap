import 'package:EcoMap/core/app_theme.dart';
import 'package:flutter/material.dart';

class SnackBarManager {
  static final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static GlobalKey<ScaffoldMessengerState> get scaffoldMessengerKey =>
      _scaffoldMessengerKey;

  static void showSuccessSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showErrorSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  static void showInfoSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}