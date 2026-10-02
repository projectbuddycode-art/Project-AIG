import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/features/camera/preset_studio/services/preset_manager.dart';
import 'package:aig/features/camera/presentation/experience/camera_hud.dart';
import 'package:aig/features/camera/presentation/experience/capture_overlay.dart';
import 'package:aig/features/camera/presentation/experience/exposure_indicator.dart';
import 'package:aig/features/camera/presentation/experience/focus_indicator.dart';
import 'package:aig/features/camera/presentation/experience/manual_control_panel.dart';
import 'package:aig/features/camera/presentation/experience/zoom_indicator.dart';

class PremiumCameraScreen extends ConsumerStatefulWidget {
  const PremiumCameraScreen({super.key});

  @override
  ConsumerState<PremiumCameraScreen> createState() =>
      _PremiumCameraScreenState();
}

class _PremiumCameraScreenState extends ConsumerState<PremiumCameraScreen> {
  final _presetManager = const PresetManager();
  String _selectedPresetId = 'diamond-luxury-360';
  bool _isRecording = false;
  final double _zoom = 1.0;
  final double _exposure = 0.0;
  final bool _focusVisible = true;

  @override
  Widget build(BuildContext context) {
    final presets = _presetManager.builtInPresets;
    final selectedPreset = presets.firstWhere(
      (preset) => preset.id == _selectedPresetId,
      orElse: () => presets.first,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(color: Colors.black),
          Positioned.fill(
            child: Center(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white24),
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      left: 24,
                      top: 24,
                      child: CameraHUD(
                        title: 'Luxury Capture',
                        subtitle: 'Preset-driven jewelry photography',
                      ),
                    ),
                    Positioned(
                      right: 24,
                      top: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ExposureIndicator(value: _exposure),
                          const SizedBox(height: 8),
                          ZoomIndicator(zoom: _zoom),
                        ],
                      ),
                    ),
                    Positioned.fill(
                      child: FocusIndicator(visible: _focusVisible),
                    ),
                    Positioned(
                      left: 24,
                      bottom: 24,
                      child: SizedBox(
                        width: 280,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ManualControlPanel(
                              key: ValueKey(selectedPreset.id),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedPresetId,
                              decoration: const InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(),
                              ),
                              items: presets
                                  .map(
                                    (preset) => DropdownMenuItem(
                                      value: preset.id,
                                      child: Text(preset.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedPresetId = value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 24,
                      bottom: 24,
                      child: ElevatedButton(
                        onPressed: () =>
                            setState(() => _isRecording = !_isRecording),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        child: Text(
                          _isRecording ? 'Stop Capture' : 'Start Capture',
                        ),
                      ),
                    ),
                    CaptureOverlay(
                      isRecording: _isRecording,
                      progress: _isRecording ? 0.62 : 0.0,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
