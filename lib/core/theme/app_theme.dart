import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

abstract class AppTheme {
  AppTheme._();

  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.accentGoldDark,
    brightness: Brightness.light,
  ).copyWith(
    secondary: AppColors.accentGold,
    onSecondary: AppColors.background,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    error: const Color(0xFFB00020),
    onError: AppColors.background,
  );

  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.accentGold,
    brightness: Brightness.dark,
  ).copyWith(
    secondary: AppColors.accentGoldLight,
    onSecondary: AppColors.textPrimary,
    surface: const Color(0xFF171B24),
    onSurface: const Color(0xFFF5F1E8),
    error: const Color(0xFFFFB4AB),
    onError: AppColors.background,
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    brightness: Brightness.light,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: AppTypography.headline.copyWith(color: AppColors.textPrimary),
      surfaceTintColor: AppColors.background,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 4,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.large)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentGoldDark,
        foregroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.large)),
        ),
        elevation: 0,
        textStyle: AppTypography.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentGoldDark,
        textStyle: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        side: BorderSide(color: AppColors.border),
        textStyle: AppTypography.subtitle,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
      ),
      showDragHandle: true,
      modalElevation: 10,
      backgroundColor: AppColors.surface,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: AppTypography.body.copyWith(color: AppColors.background),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.large)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.secondaryBackground,
      hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        borderSide: BorderSide(color: AppColors.accentGoldDark),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      elevation: 0,
      selectedItemColor: AppColors.accentGoldDark,
      unselectedItemColor: AppColors.textMuted,
      selectedLabelStyle: AppTypography.subtitle,
      unselectedLabelStyle: AppTypography.subtitle,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
      displayMedium: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    splashFactory: InkSparkle.splashFactory,
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    scaffoldBackgroundColor: const Color(0xFF0F1117),
    canvasColor: const Color(0xFF0F1117),
    brightness: Brightness.dark,
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF0F1117),
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.surface),
      titleTextStyle: AppTypography.headline.copyWith(color: AppColors.surface),
      surfaceTintColor: const Color(0xFF0F1117),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF171B24),
      elevation: 4,
      shadowColor: Color(0x33000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.large)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.large)),
        ),
        elevation: 0,
        textStyle: AppTypography.button.copyWith(color: AppColors.textPrimary),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1F2431),
      hintStyle: AppTypography.body.copyWith(color: const Color(0xFF7F97B8)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        borderSide: const BorderSide(color: Color(0xFF2D3545)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        borderSide: const BorderSide(color: Color(0xFF2D3545)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        borderSide: const BorderSide(color: AppColors.accentGold),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large))),
      showDragHandle: true,
      modalElevation: 10,
      backgroundColor: Color(0xFF171B24),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surface,
      contentTextStyle: AppTypography.body.copyWith(color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Color(0xFFF5F1E8)),
      displayMedium: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xFFF5F1E8)),
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFFF5F1E8)),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFFF5F1E8)),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFF5F1E8)),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFFF5F1E8)),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFFBBC3D1)),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    splashFactory: InkSparkle.splashFactory,
  );
}

