import 'dart:async';
import 'package:ecomap/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers/providers.dart';
import 'core/router/app_router.dart';
import 'data/data_sources/supabase_client.dart';

Future<void> main() async {
  // Assurez-vous que les bindings Flutter sont initialisés
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les fournisseurs globaux
  final sharedPreferences = await SharedPreferences.getInstance();

  try {
    // Charger les variables d'environnement
    await dotenv.load(fileName: '.env');

    // Initialiser Supabase
    await SupabaseClient.initialize();
  } catch (e) {
    debugPrint('❌ Erreur lors de l\'initialisation: $e');
  }

  // Lancer l'application avec les fournisseurs configurés
  runApp(
    ProviderScope(
      overrides: [
        // Fournisseur pour SharedPreferences
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EcoMap',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
