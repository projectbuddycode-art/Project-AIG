import 'package:flutter/material.dart';
import 'package:aig/core/theme/app_design_tokens.dart';

class ExportAppBar extends StatelessWidget {
  const ExportAppBar({super.key});

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
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              'Export',
              style: AppTypography.headline.copyWith(fontSize: 20),
            ),
          ),

        ],
      ),
    );
  }
}
