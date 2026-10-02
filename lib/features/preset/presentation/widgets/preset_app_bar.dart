import 'package:flutter/material.dart';
import 'package:aig/core/theme/app_design_tokens.dart';

class PresetAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PresetAppBar({super.key, required this.onCreate, this.onBack});

  final VoidCallback onCreate;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: AppShadow.soft,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              'Presets',
              style: AppTypography.headline.copyWith(fontSize: 20),
            ),
          ),

          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('New Preset'),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
