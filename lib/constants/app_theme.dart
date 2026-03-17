import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized Theme Configuration for MEDIKU App
///
/// Design System based on nature-inspired green palette:
/// - Primary: Dark Forest Green (#144425)
/// - Background: Off-White (#F7F9F7)
/// - Cards: Pure White (#FFFFFF) with soft shadow
/// - Text: Almost Black (#0D1F14) primary, Muted Green (#6B7A70) secondary
/// - Status: Green (#2D8653), Amber (#D97706), Red (#D94F4F)

class AppTheme {
  AppTheme._(); // Private constructor

  // ============================================
  // BORDER RADIUS TOKENS
  // ============================================
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusCard = 16.0;

  // ============================================
  // SPACING TOKENS
  // ============================================
  static const double spaceXSmall = 4.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 12.0;
  static const double spaceLarge = 16.0;
  static const double spaceXLarge = 24.0;
  static const double spaceXXLarge = 32.0;

  // ============================================
  // ELEVATION/SHADOW TOKENS
  // ============================================
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x12144425), // #144425 with 7% opacity
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> cardShadowLight = [
    BoxShadow(
      color: Color(0x0D144425), // #144425 with 5% opacity
      blurRadius: 8,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  // ============================================
  // TYPOGRAPHY TOKENS
  // ============================================
  static const String _baseFontFamily = 'Plus Jakarta Sans';
  static String get fontFamily => kIsWeb ? 'packages/mediku/$_baseFontFamily' : _baseFontFamily;

  // Metric numbers (health data)
  static TextStyle metricNumber(BuildContext context) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      height: 1.2,
    );
  }

  // Metric numbers for status colors
  static TextStyle metricNumberColored(BuildContext context, Color color) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.2,
    );
  }

  // Card labels
  static TextStyle get cardLabel => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Screen titles
  static TextStyle get screenTitle => TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // Section headings
  static TextStyle get sectionTitle => TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // Body text (minimum 16sp for elderly users)
  static TextStyle get bodyLarge => TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodySmall => TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // Button text
  static TextStyle get buttonText => TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.5,
    letterSpacing: 0.5,
  );

  // AppBar title
  static TextStyle get appBarTitle => TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // ============================================
  // CARD DECORATION
  // ============================================
  static BoxDecoration get cardDecoration {
    return BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(radiusCard),
      boxShadow: cardShadow,
    );
  }

  static BoxDecoration get cardDecorationLight {
    return BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(radiusCard),
      boxShadow: cardShadowLight,
    );
  }

  static BoxDecoration cardDecorationWithBorder({Color? borderColor}) {
    return BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(radiusCard),
      boxShadow: cardShadow,
      border: Border.all(color: borderColor ?? AppColors.divider, width: 1),
    );
  }

  // ============================================
  // INPUT DECORATION THEME
  // ============================================
  static InputDecorationTheme get inputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spaceLarge,
        vertical: spaceMedium,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: AppColors.statusRed),
      ),
      hintStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
    );
  }

  // ============================================
  // ELEVATED BUTTON THEME
  // ============================================
  static ElevatedButtonThemeData get elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        minimumSize: const Size(48, 48), // Touch target
        padding: const EdgeInsets.symmetric(
          horizontal: spaceLarge,
          vertical: spaceMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: buttonText,
      ),
    );
  }

  // ============================================
  // TEXT BUTTON THEME
  // ============================================
  static TextButtonThemeData get textButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(48, 48), // Touch target
        padding: const EdgeInsets.symmetric(
          horizontal: spaceMedium,
          vertical: spaceSmall,
        ),
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================
  // OUTLINED BUTTON THEME
  // ============================================
  static OutlinedButtonThemeData get outlinedButtonTheme {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        minimumSize: const Size(48, 48), // Touch target
        padding: const EdgeInsets.symmetric(
          horizontal: spaceLarge,
          vertical: spaceMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================
  // APP BAR THEME
  // ============================================
  static AppBarTheme get appBarTheme {
    return AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: appBarTitle,
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
    );
  }

  // ============================================
  // BOTTOM NAVIGATION BAR THEME
  // ============================================
  static BottomNavigationBarThemeData get bottomNavTheme {
    return BottomNavigationBarThemeData(
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    );
  }

  // ============================================
  // CARD THEME
  // ============================================
  static CardThemeData get cardTheme {
    return CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusCard),
      ),
      margin: const EdgeInsets.all(0),
    );
  }

  // ============================================
  // CHIP THEME
  // ============================================
  static ChipThemeData get chipTheme {
    return ChipThemeData(
      backgroundColor: AppColors.primarySurface,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      secondaryLabelStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: spaceMedium,
        vertical: spaceSmall,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXLarge),
      ),
    );
  }

  // ============================================
  // DIVIDER THEME
  // ============================================
  static DividerThemeData get dividerTheme {
    return const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    );
  }

  // ============================================
  // SNACKBAR THEME
  // ============================================
  static SnackBarThemeData get snackBarTheme {
    return SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textOnPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      behavior: SnackBarBehavior.floating,
    );
  }

  // ============================================
  // DIALOG THEME
  // ============================================
  static DialogThemeData get dialogTheme {
    return DialogThemeData(
      backgroundColor: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      titleTextStyle: screenTitle,
      contentTextStyle: bodyLarge,
    );
  }

  // ============================================
  // BOTTOM SHEET THEME
  // ============================================
  static BottomSheetThemeData get bottomSheetTheme {
    return BottomSheetThemeData(
      backgroundColor: AppColors.card,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXLarge)),
      ),
    );
  }

  // ============================================
  // MAIN THEME DATA
  // ============================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.primarySurface,
        onPrimaryContainer: AppColors.primary,
        secondary: AppColors.primaryLight,
        onSecondary: AppColors.textOnPrimary,
        secondaryContainer: AppColors.primarySurface,
        onSecondaryContainer: AppColors.primary,
        surface: AppColors.card,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surface,
        onSurfaceVariant: AppColors.textSecondary,
        error: AppColors.statusRed,
        onError: AppColors.textOnPrimary,
        outline: AppColors.divider,
        shadow: AppColors.primary,
      ),
      appBarTheme: appBarTheme,
      bottomNavigationBarTheme: bottomNavTheme,
      cardTheme: cardTheme,
      chipTheme: chipTheme,
      dividerTheme: dividerTheme,
      elevatedButtonTheme: elevatedButtonTheme,
      textButtonTheme: textButtonTheme,
      outlinedButtonTheme: outlinedButtonTheme,
      inputDecorationTheme: inputDecorationTheme,
      snackBarTheme: snackBarTheme,
      dialogTheme: dialogTheme,
      bottomSheetTheme: bottomSheetTheme,
    );
  }
}
