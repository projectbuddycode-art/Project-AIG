import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

class CommonBottomNavigation extends StatelessWidget {
  const CommonBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.borderOf(context), width: 1.1),
        boxShadow: AppShadow.soft,
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: AppColors.textMutedOf(context),
        selectedLabelStyle: AppTypography.subtitle.copyWith(color: Theme.of(context).colorScheme.primary),
        unselectedLabelStyle: AppTypography.subtitle.copyWith(color: AppColors.textMutedOf(context)),
        showUnselectedLabels: true,
        items: items,
      ),
    );
  }
}
