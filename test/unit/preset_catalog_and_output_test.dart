import 'package:flutter_test/flutter_test.dart';

import 'package:aig/features/camera/preset_studio/models/camera_preset.dart';
import 'package:aig/features/camera/preset_studio/services/preset_manager.dart';
import 'package:aig/features/camera/preset_studio/services/preset_validation.dart';
import 'package:aig/features/processing/models/video_inspection.dart';

void main() {
  test('required advertising presets exist and stay distinct', () {
    const manager = PresetManager();
    final names = manager.builtInPresets.map((preset) => preset.name).toSet();
    expect(
      names,
      containsAll(<String>[
        'Classic 360 Product Showcase',
        'Luxury Slow Rotation',
        'Diamond Brilliance',
        'Close-up Detail',
        'Gold Jewelry Showcase',
        'E-commerce Product Video',
        'Social Media Reel',
        'Custom Product Video',
      ]),
    );
    final signatures = manager.builtInPresets
        .map(
          (preset) =>
              '${preset.id}|${preset.machineSpeed}|${preset.aspectRatio}|${preset.processingLook}|${preset.captureDurationSeconds}',
        )
        .toSet();
    expect(signatures.length, manager.builtInPresets.length);
  });

  test('preset json round-trip preserves machine and grade fields', () {
    const manager = PresetManager();
    final source = manager.getPreset('full-360-showcase');
    final restored = CameraPreset.fromJson(source.toJson());
    expect(restored.id, source.id);
    expect(restored.machineSpeed, source.machineSpeed);
    expect(restored.aspectRatio, '1:1');
    expect(restored.backgroundTreatment, BackgroundTreatment.darkened);
    expect(restored.allowUpscale, isFalse);
  });

  test('preset validation rejects unsafe values', () {
    const validation = PresetValidation();
    const manager = PresetManager();
    expect(validation.validate(manager.builtInPresets.first), isNull);
    expect(
      validation.validate(
        manager.builtInPresets.first.copyWith(machineSpeed: 0),
      ),
      contains('speed'),
    );
    expect(
      validation.validate(
        manager.builtInPresets.first.copyWith(captureDurationSeconds: 0),
      ),
      contains('duration'),
    );
  });

  test('square output never claims 1080p for 576 source', () {
    const inspection = VideoInspection(
      valid: true,
      message: 'ok',
      width: 576,
      height: 576,
      durationMs: 15700,
    );
    expect(inspection.squareOutputEdge, 576);
    expect(inspection.isPlausibleDuration, isTrue);
  });

  test('background treatment labels do not claim cut-out', () {
    expect(
      backgroundTreatmentLabel(BackgroundTreatment.darkened),
      contains('not cut-out'),
    );
    expect(
      backgroundTreatmentLabel(BackgroundTreatment.original),
      contains('Original'),
    );
  });
}
