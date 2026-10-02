import 'package:flutter/material.dart';

import 'studio_panel_card.dart';

class StudioFloatingPanel extends StatelessWidget {
  const StudioFloatingPanel({super.key, required this.child, this.width});

  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return StudioPanelCard(width: width, child: child);
  }
}
