import 'package:flutter/material.dart';

class ExposureIndicator extends StatelessWidget {
  const ExposureIndicator({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.brightness_6_outlined),
          const SizedBox(width: 8),
          Text(value.toStringAsFixed(2)),
        ],
      ),
    );
  }
}
