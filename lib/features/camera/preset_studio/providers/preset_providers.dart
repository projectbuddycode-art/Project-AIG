import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/features/camera/preset_studio/models/camera_preset.dart';
import 'package:aig/features/camera/preset_studio/services/preset_manager.dart';
import 'package:aig/features/camera/preset_studio/services/preset_store.dart';
import 'package:aig/features/camera/preset_studio/services/preset_validation.dart';

class PresetCatalogNotifier extends StateNotifier<List<CameraPreset>> {
  PresetCatalogNotifier({
    PresetManager manager = const PresetManager(),
    PresetStore store = const PresetStore(),
    PresetValidation validation = const PresetValidation(),
  }) : _manager = manager,
       _store = store,
       _validation = validation,
       super(manager.builtInPresets) {
    _load();
  }

  final PresetManager _manager;
  final PresetStore _store;
  final PresetValidation _validation;

  Future<void> _load() async {
    final custom = await _store.loadCustom();
    if (!mounted) {
      return;
    }
    state = _merge(custom);
  }

  List<CameraPreset> _merge(List<CameraPreset> custom) {
    final builtIn = _manager.builtInPresets;
    final builtInIds = builtIn.map((preset) => preset.id).toSet();
    final extras = custom
        .where((preset) => !builtInIds.contains(preset.id))
        .toList();
    return <CameraPreset>[...extras, ...builtIn];
  }

  CameraPreset byId(String id) {
    return state.firstWhere(
      (preset) => preset.id == id,
      orElse: () => _manager.getPreset(id),
    );
  }

  Future<String?> upsert(CameraPreset preset) async {
    final error = _validation.validate(preset);
    if (error != null) {
      return error;
    }
    final next = [
      preset.copyWith(isCustom: true),
      ...state.where((item) => item.id != preset.id),
    ];
    state = next;
    await _store.saveCustom(next);
    return null;
  }

  Future<String?> duplicate(CameraPreset preset) {
    return upsert(
      _manager.duplicatePreset(preset, nameOverride: '${preset.name} Copy'),
    );
  }

  Future<void> delete(String id) async {
    final target = state.where((preset) => preset.id == id).toList();
    if (target.isEmpty || !target.first.isCustom) {
      return;
    }
    final next = state.where((preset) => preset.id != id).toList();
    state = next;
    await _store.saveCustom(next);
  }
}

final presetCatalogProvider =
    StateNotifierProvider<PresetCatalogNotifier, List<CameraPreset>>((ref) {
      return PresetCatalogNotifier();
    });
