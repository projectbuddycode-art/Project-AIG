import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:aig/features/camera/preset_studio/models/camera_preset.dart';

class PresetStore {
  const PresetStore();

  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/aig_custom_presets.json');
  }

  Future<List<CameraPreset>> loadCustom() async {
    try {
      final file = await _file();
      if (!file.existsSync()) {
        return const [];
      }
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        return const [];
      }
      final items = decoded['presets'];
      if (items is! List) {
        return const [];
      }
      return items
          .whereType<Map>()
          .map((item) => CameraPreset.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveCustom(List<CameraPreset> presets) async {
    final file = await _file();
    final custom = presets.where((preset) => preset.isCustom).toList();
    await file.writeAsString(
      jsonEncode(<String, Object?>{
        'presets': custom.map((preset) => preset.toJson()).toList(),
      }),
      flush: true,
    );
  }
}
