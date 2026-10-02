import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

class PremiumButton extends StatelessWidget {
  const PremiumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.width,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final onPrimary = enabled
        ? Theme.of(context).colorScheme.onPrimary
        : AppColors.textSecondary.withValues(alpha: 0.6);
    final disabledColor = AppColors.textSecondary.withValues(alpha: 0.35);
    return AnimatedContainer(
      duration: AppAnimation.standard,
      width: width,
      height: height,
      constraints: width == null ? BoxConstraints(minHeight: height) : null,
      decoration: BoxDecoration(
        color: enabled ? AppColors.accentGoldDark : disabledColor,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: enabled ? AppShadow.elevated : null,
        gradient: enabled
            ? const LinearGradient(
                colors: [AppColors.accentGoldDark, AppColors.accentGold],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.large),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    IconTheme(
                      data: IconThemeData(
                        size: 18,
                        color: onPrimary,
                      ),
                      child: icon!,
                    ),
                    const SizedBox(width: AppSpacing.s),
                  ],
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: AppTypography.button.copyWith(color: onPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
