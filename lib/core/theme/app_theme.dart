import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Super Swipe Theme - Cute, Friendly Aesthetic
class AppTheme {
  AppTheme._();

  // ============ Color Palette ============

  // Primary Colors - Soft Coral/Peach
  static const Color primaryColor = Color(0xFFFF8A7A);
  static const Color primaryLight = Color(0xFFFFB5A7);
  static const Color primaryDark = Color(0xFFE85D4A);

  // Secondary Colors - Light Mint/Sage
  static const Color secondaryColor = Color(0xFF98D4BB);
  static const Color secondaryLight = Color(0xFFBFE8D6);
  static const Color secondaryDark = Color(0xFF6BB89A);

  // Accent Colors - Warm Yellow
  static const Color accentColor = Color(0xFFFFD882);
  static const Color accentLight = Color(0xFFFFE8B5);

  // Background Colors - Warm Beige/Cream
  static const Color backgroundColor = Color(0xFFFFF8F0);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFBF7);

  // Text Colors
  static const Color textPrimary = Color(0xFF3D3D3D);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status Colors
  static const Color successColor = Color(0xFF7BC67E);
  static const Color errorColor = Color(0xFFE57373);
  static const Color warningColor = Color(0xFFFFB74D);

  // ============ Border Radius ============

  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 28.0;

  static BorderRadius get borderRadiusSmall =>
      BorderRadius.circular(radiusSmall);
  static BorderRadius get borderRadiusMedium =>
      BorderRadius.circular(radiusMedium);
  static BorderRadius get borderRadiusLarge =>
      BorderRadius.circular(radiusLarge);
  static BorderRadius get borderRadiusXLarge =>
      BorderRadius.circular(radiusXLarge);

  // ============ Shadows ============

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // ============ Spacing ============

  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // ============ Theme Data ============

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryLight,
        secondary: secondaryColor,
        secondaryContainer: secondaryLight,
        tertiary: accentColor,
        tertiaryContainer: accentLight,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: textOnPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onError: textOnPrimary,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: borderRadiusLarge),
        margin: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingS,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(borderRadius: borderRadiusLarge),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingM,
            vertical: spacingS,
          ),
          shape: RoundedRectangleBorder(borderRadius: borderRadiusMedium),
          textStyle: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(borderRadius: borderRadiusLarge),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingM,
        ),
        border: OutlineInputBorder(
          borderRadius: borderRadiusLarge,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusLarge,
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusLarge,
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadiusLarge,
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadiusLarge,
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        hintStyle: GoogleFonts.nunito(color: textLight, fontSize: 14),
        labelStyle: GoogleFonts.nunito(color: textSecondary, fontSize: 14),
        errorStyle: GoogleFonts.nunito(color: errorColor, fontSize: 12),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: borderRadiusLarge),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: secondaryLight,
        labelStyle: GoogleFonts.nunito(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: borderRadiusMedium),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingS,
          vertical: spacingXS,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: borderRadiusXLarge),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        contentTextStyle: GoogleFonts.nunito(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.nunito(color: surfaceColor, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: borderRadiusMedium),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: _buildTextTheme(),
    );
  }

  static TextTheme _buildTextTheme() {
    final baseTheme = GoogleFonts.interTextTheme();

    // Helper to add fallback fonts and custom styles
    TextStyle style(
      TextStyle? base,
      double size,
      FontWeight weight,
      Color color,
    ) {
      return (base ?? const TextStyle()).copyWith(
        fontSize: size,
        fontWeight: weight,
        color: color,
        fontFamilyFallback: <String>['Noto Sans', 'Arial'],
      );
    }

    return baseTheme.copyWith(
      displayLarge: style(
        baseTheme.displayLarge,
        57,
        FontWeight.w400,
        textPrimary,
      ),
      displayMedium: style(
        baseTheme.displayMedium,
        45,
        FontWeight.w400,
        textPrimary,
      ),
      displaySmall: style(
        baseTheme.displaySmall,
        36,
        FontWeight.w400,
        textPrimary,
      ),
      headlineLarge: style(
        baseTheme.headlineLarge,
        32,
        FontWeight.w700,
        textPrimary,
      ),
      headlineMedium: style(
        baseTheme.headlineMedium,
        28,
        FontWeight.w700,
        textPrimary,
      ),
      headlineSmall: style(
        baseTheme.headlineSmall,
        24,
        FontWeight.w700,
        textPrimary,
      ),
      titleLarge: style(baseTheme.titleLarge, 22, FontWeight.w600, textPrimary),
      titleMedium: style(
        baseTheme.titleMedium,
        16,
        FontWeight.w600,
        textPrimary,
      ),
      titleSmall: style(baseTheme.titleSmall, 14, FontWeight.w600, textPrimary),
      bodyLarge: style(baseTheme.bodyLarge, 16, FontWeight.w400, textPrimary),
      bodyMedium: style(baseTheme.bodyMedium, 14, FontWeight.w400, textPrimary),
      bodySmall: style(baseTheme.bodySmall, 12, FontWeight.w400, textSecondary),
      labelLarge: style(baseTheme.labelLarge, 14, FontWeight.w600, textPrimary),
      labelMedium: style(
        baseTheme.labelMedium,
        12,
        FontWeight.w600,
        textPrimary,
      ),
      labelSmall: style(
        baseTheme.labelSmall,
        11,
        FontWeight.w600,
        textSecondary,
      ),
    );
  }
}
