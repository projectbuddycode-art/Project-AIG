import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:flutter/material.dart';

class StudioCaptureButton extends StatelessWidget {
  const StudioCaptureButton({
    super.key,
    required this.onTap,
    this.recording = false,
    this.enabled = true,
    this.videoMode = false,
  });

  final VoidCallback onTap;
  final bool recording;
  final bool enabled;
  final bool videoMode;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: recording
          ? 'Stop recording'
          : (videoMode ? 'Record video' : 'Take photo'),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: AppAnimation.standard,
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: recording || videoMode
                  ? [const Color(0xFFE53935), const Color(0xFFB71C1C)]
                  : [AppColors.background, AppColors.accentGoldLight],
              stops: const [0.1, 1.0],
            ),
            boxShadow: AppShadow.elevated,
            border: Border.all(
              color: enabled ? AppColors.accentGoldDark : AppColors.border,
              width: 2,
            ),
          ),
          child: Center(
            child: AnimatedContainer(
              duration: AppAnimation.fast,
              width: recording ? 34 : 44,
              height: recording ? 34 : 44,
              decoration: BoxDecoration(
                shape: recording ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: recording ? BorderRadius.circular(6) : null,
                color: enabled
                    ? (recording || videoMode
                          ? AppColors.background
                          : AppColors.accentGoldDark)
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
