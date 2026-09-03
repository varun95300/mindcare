import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MindCare design system — calm, clean, empathetic.
class MindCareTheme {
  // ===== COLORS =====
  // "Sage & Sand" — a calm, grounded palette for a mental-health-first app.
  // One hue family throughout (sage green + warm neutrals) instead of
  // several competing saturated colors, so the app reads as therapeutic
  // rather than a generic consumer/SaaS product.
  static const Color primary = Color(0xFF7A9E7E);       // Sage green
  static const Color primaryDark = Color(0xFF5F8163);
  static const Color primaryLight = Color(0xFFDCE8DD);
  static const Color secondary = Color(0xFFB7A98A);      // Warm taupe
  static const Color accent = Color(0xFFE8A87C);         // Soft terracotta
  static const Color background = Color(0xFFFBF8F3);     // Warm cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF4EFE6);
  static const Color textPrimary = Color(0xFF3A3A35);    // Soft charcoal
  static const Color textSecondary = Color(0xFF6B6B62);
  static const Color textLight = Color(0xFFABABA0);
  static const Color error = Color(0xFFC1584A);          // Muted brick
  static const Color success = Color(0xFF5E8F5A);        // Leaf green
  static const Color warning = Color(0xFFC9A661);        // Soft ochre

  // Domain colors — tints within the same grounded family rather than
  // unrelated hues, so the report screen doesn't feel alarmist.
  static const Color anxietyColor = Color(0xFFC98A7A);      // Dusty clay
  static const Color depressionColor = Color(0xFF7B93A8);   // Muted slate blue
  static const Color stressColor = Color(0xFFC4A661);       // Soft ochre
  static const Color interpersonalColor = Color(0xFF9B8AA6); // Muted mauve

  static Color domainColor(String domain) {
    switch (domain.toLowerCase()) {
      case 'anxiety':
        return anxietyColor;
      case 'depression':
        return depressionColor;
      case 'stress':
        return stressColor;
      case 'interpersonal / trauma':
      case 'interpersonal':
        return interpersonalColor;
      default:
        return primary;
    }
  }

  // ===== GRADIENTS =====
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7A9E7E), Color(0xFF5F8163)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF7A9E7E), Color(0xFFE8A87C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===== SPACING =====
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  // ===== BORDER RADIUS =====
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 100;

  // ===== SHADOWS =====
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  // ===== THEME DATA =====
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.nunitoTextTheme().copyWith(
        displayLarge: GoogleFonts.nunito(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.nunito(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.nunito(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        color: surface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
    );
  }
}
