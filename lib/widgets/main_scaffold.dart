import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_router.dart';
import '../core/app_theme.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Utiliser addPostFrameCallback pour s'assurer que le widget est complètement initialisé
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCurrentIndex();
    });
  }

  void _updateCurrentIndex() {
    try {
      if (mounted) {
        final location = GoRouterState.of(context).uri.path;
        switch (location) {
          case AppRouter.map:
            _currentIndex = 0;
            break;
          case AppRouter.addBin:
            _currentIndex = 1;
            break;
          case AppRouter.profile:
            _currentIndex = 2;
            break;
        }
      }
    } catch (e) {
      // En cas d'erreur, utiliser l'index par défaut (carte)
      _currentIndex = 0;
    }
  }

  void _onItemTapped(int index) {
    if (!mounted) return;
    
    setState(() {
      _currentIndex = index;
    });

    try {
      switch (index) {
        case 0:
          context.go(AppRouter.map);
          break;
        case 1:
          context.go(AppRouter.addBin);
          break;
        case 2:
          context.go(AppRouter.profile);
          break;
      }
    } catch (e) {
      // En cas d'erreur de navigation, ne rien faire
      debugPrint('Erreur de navigation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surfaceColor,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondary,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Carte',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_location),
            label: 'Ajouter',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
