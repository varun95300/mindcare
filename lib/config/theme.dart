import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/motion.dart' show SoftPageTransitionsBuilder;

/// MindCare design system: warm ivory, sage, butter and dusty coral.
///
/// Every screen takes its colours, type, radii and shadows from here, so the
/// whole app stays one calm, consistent language. Quiet luxury rather than
/// clinical: soft paper-like surfaces, muted colour, generous space.
class MindCareTheme {
  const MindCareTheme._();

  // ===== COLOURS =====
  // Roughly 65-70% ivory/cream, 15-20% sage and neutrals, 5-10% butter,
  // 5-10% coral. Muted everywhere: nothing saturated.

  /// Warm ivory: the page background.
  static const Color background = Color(0xFFF7F1E6);

  /// Warm cream: cards, dialogs and other raised surfaces.
  static const Color surface = Color(0xFFFFF9F1);

  /// A slightly deeper cream for fills (inputs, chips, quiet panels).
  static const Color surfaceVariant = Color(0xFFEFE7D8);

  /// Sage: primary actions, selection, progress, positive states.
  static const Color primary = Color(0xFFA9B7A0);

  /// Deep sage: text and icons that sit on cream and need contrast.
  static const Color primaryDark = Color(0xFF5E6D57);

  /// Pale sage tint for selected rows and soft highlights.
  static const Color primaryLight = Color(0xFFE4EADD);

  /// Muted butter: highlights, gentle information.
  static const Color secondary = Color(0xFFE7D8A8);
  static const Color butter = secondary;

  /// Darker butter for text and strokes on cream.
  static const Color butterDeep = Color(0xFFA8893A);

  /// Dusty coral: emotional accent, gentle warnings.
  static const Color accent = Color(0xFFD9A99B);
  static const Color coral = accent;

  /// Muted terracotta: genuinely important states only.
  static const Color terracotta = Color(0xFFB4604F);

  /// Deep olive charcoal: main text (never pure black).
  static const Color textPrimary = Color(0xFF3F4038);
  static const Color textSecondary = Color(0xFF77766C);
  static const Color textLight = Color(0xFFA9A698);

  /// Text/icons on a sage fill.
  static const Color onPrimary = textPrimary;

  static const Color border = Color(0xFFE4DDD0);

  // Status colours stay inside the same family.
  static const Color error = terracotta;
  static const Color success = Color(0xFF6B8560);
  static const Color warning = butterDeep;

  // Concern areas: four distinguishable but muted tones.
  static const Color anxietyColor = Color(0xFFC98F80);       // clay coral
  static const Color depressionColor = Color(0xFF7E9477);    // deep sage
  static const Color stressColor = Color(0xFFC9AE62);        // butter gold
  static const Color interpersonalColor = Color(0xFFA58F86); // warm taupe

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

  /// Mood colours (0 = stressed ... 4 = good). Never implies a diagnosis.
  static Color moodColor(int mood) {
    switch (mood) {
      case 4:
        return primary; // good: sage
      case 3:
        return const Color(0xFFC5D0BC); // calm: pale sage
      case 2:
        return const Color(0xFFE8DFD2); // okay: warm beige
      case 1:
        return accent; // low: dusty coral
      default:
        return const Color(0xFFC98F80); // stressed: deeper coral
    }
  }

  // ===== GRADIENTS =====
  // Barely-there tints only; never on buttons.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFB9C5B0), Color(0xFFA9B7A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFE4EADD), Color(0xFFF7F1E6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===== SPACING (4 / 8 / 12 / 16 / 24 / 32 / 48) =====
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  // ===== RADII =====
  static const double radiusSm = 10;
  static const double radiusMd = 14; // buttons, inputs
  static const double radiusLg = 20; // cards
  static const double radiusXl = 24; // large panels, dialogs
  static const double radiusFull = 100;

  // ===== SHADOWS: extremely soft =====
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: textPrimary.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: textPrimary.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 6),
        ),
      ];

  // ===== TYPE =====
  // Headings: DM Sans. Body: Inter. Generous line height.
  static TextStyle _heading(double size, FontWeight weight,
          {Color color = textPrimary, double? height}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height ?? 1.25,
      );

  static TextStyle _body(double size, FontWeight weight,
          {Color color = textPrimary, double height = 1.55}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );

  static TextTheme get _textTheme => TextTheme(
        displayLarge: _heading(32, FontWeight.w700),
        displayMedium: _heading(28, FontWeight.w700),
        displaySmall: _heading(24, FontWeight.w700),
        headlineLarge: _heading(22, FontWeight.w600),
        headlineMedium: _heading(20, FontWeight.w600),
        headlineSmall: _heading(18, FontWeight.w600),
        titleLarge: _heading(17, FontWeight.w600),
        titleMedium: _heading(15, FontWeight.w600),
        titleSmall: _heading(14, FontWeight.w500),
        bodyLarge: _body(16, FontWeight.w400),
        bodyMedium: _body(14, FontWeight.w400, color: textSecondary),
        bodySmall: _body(12, FontWeight.w400, color: textSecondary),
        labelLarge: _body(15, FontWeight.w600, height: 1.2),
        labelMedium: _body(13, FontWeight.w500, height: 1.2),
        labelSmall: _body(11, FontWeight.w500, height: 1.2),
      );

  // ===== THEME DATA =====
  static ThemeData get lightTheme {
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMd),
    );
    final buttonText = GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 15);

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryLight,
        onPrimaryContainer: primaryDark,
        secondary: secondary,
        onSecondary: textPrimary,
        tertiary: accent,
        onTertiary: textPrimary,
        surface: surface,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        surfaceContainerHighest: surfaceVariant,
        error: terracotta,
        onError: Colors.white,
        outline: border,
        outlineVariant: border,
      ),
      textTheme: _textTheme,
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: surfaceVariant,
          disabledForegroundColor: textLight,
          elevation: 0,
          shadowColor: textPrimary.withValues(alpha: 0.25),
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
        ).copyWith(
          // Hover: a touch brighter with a slightly stronger shadow.
          elevation: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered) ? 3 : 0),
          overlayColor: WidgetStateProperty.resolveWith((s) {
            if (s.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.22);
            }
            if (s.contains(WidgetState.pressed)) {
              return textPrimary.withValues(alpha: 0.06);
            }
            return null;
          }),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: surfaceVariant,
          disabledForegroundColor: textLight,
          elevation: 0,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          backgroundColor: surface,
          side: const BorderSide(color: border),
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDark,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: textLight),
        border: inputBorder(border),
        enabledBorder: inputBorder(border),
        focusedBorder: inputBorder(primary, 2),
        errorBorder: inputBorder(terracotta),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: border),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primaryLight,
        side: const BorderSide(color: border),
        labelStyle: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: const BorderSide(color: border),
        ),
        titleTextStyle: _heading(20, FontWeight.w600),
        contentTextStyle: _body(14, FontWeight.w400, color: textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: surface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: border),
        ),
        textStyle: _body(14, FontWeight.w500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: primary.withValues(alpha: 0.35),
        labelTextStyle: WidgetStateProperty.resolveWith((states) =>
            GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w600
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? textPrimary
                  : textSecondary,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 24,
              color: states.contains(WidgetState.selected)
                  ? textPrimary
                  : textSecondary,
            )),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _heading(20, FontWeight.w600),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SoftPageTransitionsBuilder(),
          TargetPlatform.iOS: SoftPageTransitionsBuilder(),
          TargetPlatform.windows: SoftPageTransitionsBuilder(),
          TargetPlatform.macOS: SoftPageTransitionsBuilder(),
          TargetPlatform.linux: SoftPageTransitionsBuilder(),
          TargetPlatform.fuchsia: SoftPageTransitionsBuilder(),
        },
      ),
    );
  }
}
