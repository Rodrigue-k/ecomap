import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = widget.currentIndex;
        _animationController.reset();
        _animationController.forward();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _animationController.reset();
      _animationController.forward();
    });
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        // Barre de navigation principale (hauteur réduite)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          height: 40, // Réduit de 50 à 40
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(77),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Bouton Carte
              _buildNavItem(
                icon: Icons.map_rounded,
                label: 'Carte',
                index: 0,
                isSelected: _selectedIndex == 0,
              ),
              // Espace pour le bouton flottant
              const SizedBox(width: 60),
              // Bouton Profil
              _buildNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                index: 2,
                isSelected: _selectedIndex == 2,
              ),
            ],
          ),
        ),

        // Bouton flottant central (ajusté pour overlap)
        Positioned(
          top: -20, // Réduit de -25 à -20 pour équilibrer
          child: GestureDetector(
            onTap: () => context.go('/report'),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), // Réduit vertical de 10 à 8
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isSelected ? 1.0 + (_animation.value * 0.15) : 1.0, // Subtile scale (0.2 → 0.15)
                  child: Icon(
                    icon,
                    size: 24, // Réduit de 28 à 24
                    color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[600],
                  ),
                );
              },
            ),
            const SizedBox(height: 2), // Réduit de 4 à 2
            Text(
              label,
              style: TextStyle(
                fontSize: 11, // Réduit de 12 à 11
                color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}