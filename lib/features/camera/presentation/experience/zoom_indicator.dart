import 'package:flutter/material.dart';

class ZoomIndicator extends StatelessWidget {
  const ZoomIndicator({super.key, required this.zoom});

  final double zoom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('Zoom ${zoom.toStringAsFixed(1)}x'),
    );
  }
}
