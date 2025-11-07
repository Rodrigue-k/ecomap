import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

import '../map/map_screen.dart';
import '../profile_screen.dart';
import '../waste_dump/waste_dump_report_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  final Widget child;
  const MainScreen({super.key, required this.child});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with SingleTickerProviderStateMixin {
  late final List<Widget> _pages;
  late TabController _tabController;
  int _currentPage = 0;
  final List<Color> colors = [
    const Color(0xFF4CAF50),
    const Color(0xFF2196F3),
    const Color(0xFF9C27B0),
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      const MapScreen(),
      const ProfileScreen(),
    ];
    _tabController = TabController(length: _pages.length, vsync: this);
    _tabController.animation?.addListener(_handleTabAnimation);
  }

  void _handleTabAnimation() {
    final value = _tabController.animation?.value ?? 0;
    final newPage = value.round();
    if (newPage != _currentPage && mounted) {
      setState(() {
        _currentPage = newPage;
      });
    }
  }

  @override
  void dispose() {
    _tabController.animation?.removeListener(_handleTabAnimation);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true, // Permet au contenu de s'étendre sous la barre de navigation
      body: BottomBar(
        clip: Clip.none,
        fit: StackFit.expand,
        borderRadius: BorderRadius.circular(30), // Réduit le border radius
        duration: const Duration(milliseconds: 200), // Animation plus rapide
        curve: Curves.easeInOut,
        showIcon: false,
        width: MediaQuery.of(context).size.width * 0.9,
        barColor: theme.colorScheme.primary,
        start: 1,
        end: 0,
        offset: 8, // Réduit l'offset
        barAlignment: Alignment.bottomCenter,
        iconHeight: 24, // Réduit la taille des icônes
        iconWidth: 24,
        reverse: false,
        hideOnScroll: true,
        scrollOpposite: false,
        onBottomBarHidden: () {},
        onBottomBarShown: () {},
        body: (context, controller) => TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(),
          children: _pages,
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            TabBar(
              controller: _tabController,
              indicator: const BoxDecoration(color: Colors.transparent),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              dividerColor: Colors.transparent,
              indicatorColor: Colors.transparent,
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: theme.textTheme.labelMedium,
              padding: const EdgeInsets.symmetric(vertical: 4),
              tabs: [
                const Tab(icon: Icon(Icons.map_rounded), text: 'Carte'),
                const Tab(icon: Icon(Icons.person_outline_rounded), text: 'Profil'),
              ],
              onTap: (index) {
                _tabController.animateTo(index);
              },
            ),
            Positioned(
              top: -20, // Ajuste la position verticale
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WasteDumpReportScreen(),
                    ),
                  );
                  
                  if (result == true && mounted) {
                    // TODO: Implémenter le rafraîchissement de la carte si nécessaire
                  }
                },
                backgroundColor: theme.colorScheme.secondary,
                elevation: 2,
                child: Icon(
                  Icons.add,
                  color: theme.colorScheme.onSecondary,
                  size: 28,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
