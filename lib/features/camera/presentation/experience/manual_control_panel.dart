import 'package:flutter/material.dart';

class ManualControlPanel extends StatelessWidget {
  const ManualControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manual Controls',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              Chip(label: Text('Focus')),
              Chip(label: Text('Exposure')),
              Chip(label: Text('Zoom')),
              Chip(label: Text('Grid')),
            ],
          ),
        ],
      ),
    );
  }
}
