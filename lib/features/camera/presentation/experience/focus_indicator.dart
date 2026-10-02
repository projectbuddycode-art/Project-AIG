import 'package:flutter/material.dart';

class FocusIndicator extends StatelessWidget {
  const FocusIndicator({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
