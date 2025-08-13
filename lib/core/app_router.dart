
import 'package:go_router/go_router.dart';
import '../screens/map/map_screen.dart';
import '../screens/add_bin/add_bin_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/main_scaffold.dart';

class AppRouter {
  static const String map = '/';
  static const String addBin = '/add-bin';
  static const String profile = '/profile';

  static final GoRouter router = GoRouter(
    initialLocation: map,
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: map,
            builder: (context, state) => const MapScreen(),
          ),
          /*GoRoute(
            path: addBin,
            builder: (context, state) => const AddBinScreen(),
          ),*/
          GoRoute(
            path: profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
