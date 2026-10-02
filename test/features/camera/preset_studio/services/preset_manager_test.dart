import 'package:aig/features/camera/preset_studio/services/preset_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PresetManager', () {
    test('duplicates presets with a unique id and updated name', () {
      const manager = PresetManager();
      final source = manager.builtInPresets.first;

      final duplicate = manager.duplicatePreset(
        source,
        nameOverride: 'Copy of ${source.name}',
      );

      expect(duplicate.id, isNot(source.id));
      expect(duplicate.name, 'Copy of ${source.name}');
      expect(duplicate.description, source.description);
    });

    test('removes a preset from a list without altering the rest', () {
      const manager = PresetManager();
      final presets = manager.builtInPresets;

      final updated = manager.removePreset(presets, presets.first.id);

      expect(updated, hasLength(presets.length - 1));
      expect(updated.any((preset) => preset.id == presets.first.id), isFalse);
      expect(updated.first.id, isNot(presets.first.id));
    });
  });
}
