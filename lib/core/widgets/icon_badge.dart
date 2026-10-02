import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.backgroundColor = AppColors.accentGoldLight,
    this.iconColor = AppColors.accentGoldDark,
    this.size = 44,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Icon(icon, color: iconColor, size: size * 0.55),
    );
  }
}
