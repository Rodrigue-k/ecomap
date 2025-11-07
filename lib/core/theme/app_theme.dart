import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Couleurs principales - Thème écologique
  static const Color primaryColor = Color(0xFF1E8B63); // Vert principal
  static const Color primaryLight = Color(0xFF4FBC8D); // 20% plus clair
  static const Color primaryDark = Color(0xFF155C43);  // 20% plus foncé
  static const Color primaryVariant = Color(0xFF0D3A28); // 50% plus foncé
  
  // Couleurs secondaires et d'accent
  static const Color secondaryColor = Color(0xFF8BD1D1); // Turquoise doux
  static const Color secondaryVariant = Color(0xFF5ABFBF); // Turquoise plus foncé
  static const Color accentColor = Color(0xFFFF9E7D); // Saumon
  static const Color tertiaryColor = Color(0xFF6A8EAE); // Bleu-gris

  // Dégradés
  static LinearGradient primaryGradient = const LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Couleurs de statut
  static const Color successColor = Color(0xFF00A86B); // Vert émeraude
  static const Color warningColor = Color(0xFFFFB74D); // Orange doux
  static const Color errorColor = Color(0xFFEF5350); // Rouge doux
  static const Color infoColor = Color(0xFF4FC3F7); // Bleu clair

  // Couleurs neutres
  static const Color backgroundColor = Color(0xFFF5F7F6); // Gris très clair avec une teinte verte
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Color(0xFFFFFFFF); // Blanc pur pour les cartes
  static const Color textPrimary = Color(0xFF1E2E28); // Noir avec une teinte verte
  static const Color textSecondary = Color(0xFF5A6B66); // Gris-vert moyen
  static const Color borderColor = Color(0xFFDEE5E2); // Gris très clair avec une teinte verte
  static const Color dividerColor = Color(0xFFE0E6E3); // Couleur de séparation

  // Couleurs des poubelles
  static const Color binGeneral = primaryColor; // Utilisation de la couleur primaire
  static const Color binRecyclable = Color(0xFF2E7D9A); // Bleu-vert
  static const Color binOrganic = Color(0xFF8B6B3D); // Marron terreux
  static const Color binHazardous = Color(0xFF9C4D49); // Rouge brique
  static const Color binFull = Color(0xFFD32F2F); // Rouge vif
  static const Color binMaintenance = Color(0xFF5D737E); // Gris-bleu
  static const Color binPlastic = Color(0xFF1976D2); // Bleu pour le plastique
  static const Color binGlass = Color(0xFF0288D1); // Bleu clair pour le verre
  static const Color binPaper = Color(0xFFFBC02D); // Jaune pour le papier

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryVariant,
        secondary: secondaryColor,
        secondaryContainer: secondaryVariant,
        tertiary: tertiaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: Colors.white,
        brightness: Brightness.light,
      ),

      // Typographie
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(fontSize: 16, color: textPrimary),
        bodyMedium: GoogleFonts.poppins(fontSize: 14, color: textSecondary),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
          height: 1.2,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
        actionsIconTheme: const IconThemeData(color: Colors.white, size: 24),
      ),

      // Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryColor.withOpacity(0.5),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            height: 1.5,
          ),
        ),
      ),
      
      // Boutons texte
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Boutons outline
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Cartes
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
        margin: const EdgeInsets.all(8),
      ),
      
      // Champs de formulaire
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary.withAlpha(153)),
      ),
      
      // Indicateurs de progression
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: Color(0xFFE0E0E0),
      ),
      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withAlpha(179),
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        showUnselectedLabels: true,
      ),
    );
  }
}
