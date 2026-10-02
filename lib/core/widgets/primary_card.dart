import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

class PrimaryCard extends StatelessWidget {
  const PrimaryCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.l),
    this.elevation = 12,
    this.color = AppColors.surface,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadius.medium)),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final Color color;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color == AppColors.surface
        ? AppColors.surfaceOf(context)
        : color;
    final resolvedBorder = Border.all(
      color: AppColors.borderOf(context),
      width: 1.1,
    );
    return AnimatedContainer(
      duration: AppAnimation.standard,
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: borderRadius,
        border: resolvedBorder,
        boxShadow: AppShadow.soft,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
