
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Charger les variables d'environnement
    await dotenv.load(fileName: '.env');

    // Initialiser Supabase
    await SupabaseService.initialize();

    
  } catch (e) {
    debugPrint('❌ Erreur lors de l\'initialisation: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EcoMap',
      theme: ThemeData.light(),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
