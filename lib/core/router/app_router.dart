import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/main/main_screen.dart';
import '../../presentation/screens/map/map_screen.dart';
import '../../presentation/screens/waste_dump/waste_dump_report_screen.dart';

class AppRouter {
  // Routes principales
  static const String map = '/';
  static const String addBin = '/add-bin';
  static const String profile = '/profile';

  // Routes secondaires
  static const String privacyPolicy = '/privacy-policy';
  static const String reportDump = '/report-dump';

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: map,
    debugLogDiagnostics: true,
    routes: [
      // Shell pour le layout principal avec bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          // Écran de la carte
          GoRoute(
            path: map,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MapScreen()),
          ),

          // Écran d'ajout de poubelle
          GoRoute(
            path: addBin,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: Center(
                child: Text('Ajouter une poubelle'),
              ), // TODO: Remplacer par AddBinScreen
            ),
          ),

          // Écran de profil
          GoRoute(
            path: profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: Center(
                child: Text('Profil'),
              ), // TODO: Remplacer par ProfileScreen
            ),
          ),
        ],
      ),

      // Routes indépendantes (sans bottom navigation)
      GoRoute(
        path: privacyPolicy,
        builder: (context, state) => const Center(
          child: Text('Politique de confidentialité'),
        ), // TODO: Remplacer par PrivacyPolicyScreen
      ),

      // Écran de signalement de dépotoir
      GoRoute(
        path: reportDump,
        name: 'report-dump',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: WasteDumpReportScreen()),
      ),
    ],
  );
}
