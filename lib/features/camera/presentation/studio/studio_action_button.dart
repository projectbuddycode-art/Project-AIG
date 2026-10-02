import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

class StudioActionButton extends StatelessWidget {
  const StudioActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.primary = true,
    this.width,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final background = primary ? AppColors.accentGold : AppColors.surface;
    final foreground = primary ? AppColors.background : AppColors.textPrimary;

    return AnimatedContainer(
      duration: AppAnimation.standard,
      width: width,
      height: 48,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border, width: 1.1),
        boxShadow: AppShadow.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.large),
          onTap: onPressed,
          splashColor: AppColors.accentGoldLight.withValues(alpha: 0.28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final hasFiniteWidth = constraints.maxWidth.isFinite;
                final labelText = Text(
                  label,
                  style: AppTypography.subtitle.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: hasFiniteWidth
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  children: [
                    Icon(icon, size: 18, color: foreground),
                    const SizedBox(width: AppSpacing.s),
                    hasFiniteWidth ? Flexible(child: labelText) : labelText,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
