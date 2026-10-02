import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

class StudioPanelCard extends StatelessWidget {
  const StudioPanelCard({
    super.key,
    required this.child,
    this.width,
    this.padding = const EdgeInsets.all(AppSpacing.l),
    this.borderRadius = AppRadius.large,
    this.backgroundColor = AppColors.surface,
  });

  final Widget child;
  final double? width;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimation.standard,
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border, width: 1.1),
        boxShadow: AppShadow.soft,
      ),
      child: child,
    );
  }
}
