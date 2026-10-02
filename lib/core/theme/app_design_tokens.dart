import 'package:flutter/material.dart';

abstract class AppColors {
  AppColors._();

  static const Color background = Color(0xFFFBF7EE);
  static const Color secondaryBackground = Color(0xFFF7F1E4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFCF7EE);
  static const Color border = Color(0xFFD9C8A8);
  static const Color accentGold = Color(0xFFB08934);
  static const Color accentGoldDark = Color(0xFF7F6629);
  static const Color accentGoldLight = Color(0xFFF6E7B0);
  static const Color textPrimary = Color(0xFF211F1A);
  static const Color textSecondary = Color(0xFF5E584F);
  static const Color textMuted = Color(0xFF7F776B);
  static const Color success = Color(0xFF2F9D57);
  static const Color shadow = Color(0x22000000);
  static const Color icon = Color(0xFF6E675C);
  static const Color mutedBorder = Color(0xFFDCCBB0);

  static Color backgroundOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0F1117)
        : background;
  }

  static Color surfaceOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF171B24)
        : surface;
  }

  static Color secondaryBackgroundOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1D2430)
        : secondaryBackground;
  }

  static Color borderOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2D3545)
        : border;
  }

  static Color textPrimaryOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF5F1E8)
        : textPrimary;
  }

  static Color textSecondaryOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFB7BECC)
        : textSecondary;
  }

  static Color textMutedOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF8F97A8)
        : textMuted;
  }
}

abstract class AppTypography {
  AppTypography._();

  static const TextStyle displayLarge = TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.1,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.9,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.background,
    letterSpacing: 1.1,
  );
}

abstract class AppSpacing {
  AppSpacing._();

  static const double xs = 6;
  static const double s = 12;
  static const double m = 18;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 40;
}

abstract class AppRadius {
  AppRadius._();

  static const double small = 14;
  static const double medium = 24;
  static const double large = 32;
  static const double pill = 999;
}

abstract class AppShadow {
  AppShadow._();

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 36,
      offset: Offset(0, 18),
    ),
  ];
}

abstract class AppAnimation {
  AppAnimation._();

  static const Duration standard = Duration(milliseconds: 220);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration slow = Duration(milliseconds: 260);
}
