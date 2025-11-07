import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final String hintText;

  const SearchBarWidget({
    super.key,
    this.onChanged,
    this.onTap,
    this.controller,
    this.hintText = 'Rechercher un lieu...',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SearchBar(
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        hintText: hintText,
        leading: const Icon(Icons.search, color: Colors.grey),
        backgroundColor: MaterialStateProperty.all(Colors.white),
        elevation: MaterialStateProperty.all(2.0),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.1),
              width: 1.0,
            ),
          ),
        ),
        constraints: const BoxConstraints(
          minHeight: 48,
          maxHeight: 48,
        ),
        textStyle: MaterialStateProperty.all(
          theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        hintStyle: MaterialStateProperty.all(
          theme.textTheme.bodyLarge?.copyWith(
            color: theme.hintColor,
          ),
        ),
      ),
    );
  }
}
