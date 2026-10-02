import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

class PremiumDivider extends StatelessWidget {
  const PremiumDivider({
    super.key,
    this.thickness = 1,
    this.indent = 0,
    this.endIndent = 0,
  });

  final double thickness;
  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: thickness,
      thickness: thickness,
      color: AppColors.border,
      indent: indent,
      endIndent: endIndent,
    );
  }
}
