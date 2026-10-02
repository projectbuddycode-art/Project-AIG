import 'package:flutter/material.dart';
import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:aig/core/widgets/primary_card.dart';

class GalleryAppBar extends StatelessWidget {
  const GalleryAppBar({
    super.key,
    required this.title,
    required this.onBack,
    required this.onSearchPressed,
    required this.onFilterPressed,
    required this.onSortPressed,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onSearchPressed;
  final VoidCallback onFilterPressed;
  final VoidCallback onSortPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.l, AppSpacing.s),
      child: PrimaryCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
        child: Row(
          children: [
            IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_ios_new_rounded)),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.headline.copyWith(fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                IconButton(onPressed: onSearchPressed, icon: const Icon(Icons.search_rounded)),
                IconButton(onPressed: onFilterPressed, icon: const Icon(Icons.filter_list_rounded)),
                IconButton(onPressed: onSortPressed, icon: const Icon(Icons.sort_rounded)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
