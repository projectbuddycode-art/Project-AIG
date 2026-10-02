import 'package:flutter/material.dart';
import 'package:aig/core/theme/app_design_tokens.dart';

class ExportSuccessDialog extends StatelessWidget {
  const ExportSuccessDialog({super.key, required this.filesExported, required this.destination, required this.timeTaken});

  final int filesExported;
  final String destination;
  final String timeTaken;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
      title: const Text('Export Successful'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$filesExported files exported', style: AppTypography.subtitle),
        const SizedBox(height: AppSpacing.s),
        Text('Destination: $destination', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.s),
        Text('Time taken: $timeTaken', style: AppTypography.label.copyWith(color: AppColors.textSecondary)),
      ]),
      actions: [
        OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('View Gallery')),
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
      ],
    );
  }
}
