import 'package:flutter/material.dart';

class CaptureOverlay extends StatelessWidget {
  const CaptureOverlay({
    super.key,
    required this.isRecording,
    required this.progress,
  });

  final bool isRecording;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Icon(
                  isRecording
                      ? Icons.fiber_manual_record
                      : Icons.circle_outlined,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isRecording ? 'Recording' : 'Ready',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
        ),
      ],
    );
  }
}
