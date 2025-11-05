import 'package:go_router/go_router.dart';
import '../../presentation/screens/map_screen.dart';
import '../../presentation/widgets/main_scaffold.dart';

class AppRouter {
  static const String map = '/';
  static const String addBin = '/add-bin';
  static const String profile = '/profile';
  static const String privacyPolicy = '/privacy-policy';

  static final GoRouter router = GoRouter(
    initialLocation: map,
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: map, builder: (context, state) => const MapScreen()),
          /*GoRoute(
            path: addBin,
            builder: (context, state) => const AddBinScreen(),
          ),*/
          /*GoRoute(
            path: profile,
            builder: (context, state) => const ProfileScreen(),
          ),*/
          /*GoRoute(
            path: privacyPolicy,
            builder: (context, state) => const PrivacyPolicyScreen(),
          ),*/
        ],
      ),
    ],
  );
}
