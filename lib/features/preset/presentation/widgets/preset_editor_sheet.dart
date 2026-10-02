import 'package:flutter/material.dart';

import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:aig/features/camera/models/jewelry_filter.dart';
import 'package:aig/features/camera/preset_studio/models/camera_preset.dart';
import 'package:aig/features/camera/preset_studio/services/preset_validation.dart';

class PresetEditorSheet extends StatefulWidget {
  const PresetEditorSheet({super.key, this.initial});

  final CameraPreset? initial;

  @override
  State<PresetEditorSheet> createState() => _PresetEditorSheetState();
}

class _PresetEditorSheetState extends State<PresetEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late int _duration;
  late int _speed;
  late int _intensity;
  late bool _lightOn;
  late bool _requiresMachine;
  late String _direction;
  late String _aspect;
  late BackgroundTreatment _background;
  late JewelryProcessingLook _look;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?.name ?? '');
    _description = TextEditingController(text: initial?.description ?? '');
    _duration = initial?.captureDurationSeconds ?? 8;
    _speed = initial?.machineSpeed ?? 24;
    _intensity = initial?.lightIntensity ?? 80;
    _lightOn = initial?.lightOn ?? true;
    _requiresMachine = initial?.requiresMachine ?? true;
    _direction = initial?.rotationDirection ?? 'cw';
    _aspect = initial?.aspectRatio ?? '1:1';
    _background = initial?.backgroundTreatment ?? BackgroundTreatment.darkened;
    _look = initial?.processingLook ?? JewelryProcessingLook.luxuryDark;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final base = widget.initial;
    final preset =
        (base ??
                CameraPreset(
                  id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
                  name: _name.text.trim(),
                  description: _description.text.trim(),
                ))
            .copyWith(
              name: _name.text.trim(),
              description: _description.text.trim(),
              advertisingPurpose: 'Custom product video',
              captureDurationSeconds: _duration,
              machineSpeed: _speed,
              lightIntensity: _intensity,
              lightOn: _lightOn,
              requiresMachine: _requiresMachine,
              rotationDirection: _direction,
              aspectRatio: _aspect,
              backgroundTreatment: _background,
              processingLook: _look,
              isVideoPreset: true,
              isCustom: true,
              rotationMode: _requiresMachine
                  ? MachineRotationMode.continuous
                  : MachineRotationMode.none,
              category: 'Custom',
            );
    final error = const PresetValidation().validate(preset);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop(preset);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.large),
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.initial == null ? 'Create preset' : 'Edit preset',
                  style: AppTypography.headline.copyWith(fontSize: 18),
                ),
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Preset name'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter a name'
                      : null,
                ),
                const SizedBox(height: AppSpacing.s),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.m),
                Text('Record ${_duration}s', style: AppTypography.subtitle),
                Slider(
                  value: _duration.toDouble(),
                  min: 4,
                  max: 20,
                  divisions: 16,
                  onChanged: (value) =>
                      setState(() => _duration = value.round()),
                ),
                Text('Machine speed $_speed', style: AppTypography.subtitle),
                Slider(
                  value: _speed.toDouble(),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  onChanged: (value) => setState(() => _speed = value.round()),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('GPIO 33 light'),
                  value: _lightOn,
                  onChanged: (value) => setState(() => _lightOn = value),
                ),
                if (_lightOn) ...[
                  Text('Intensity $_intensity', style: AppTypography.subtitle),
                  Slider(
                    value: _intensity.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    onChanged: (value) =>
                        setState(() => _intensity = value.round()),
                  ),
                ],
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Requires connected machine'),
                  value: _requiresMachine,
                  onChanged: (value) =>
                      setState(() => _requiresMachine = value),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _direction,
                  decoration: const InputDecoration(labelText: 'Rotation'),
                  items: const [
                    DropdownMenuItem(value: 'cw', child: Text('Clockwise')),
                    DropdownMenuItem(
                      value: 'ccw',
                      child: Text('Counter-clockwise'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _direction = value ?? 'cw'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _aspect,
                  decoration: const InputDecoration(labelText: 'Aspect'),
                  items: const [
                    DropdownMenuItem(value: '1:1', child: Text('Square 1:1')),
                    DropdownMenuItem(
                      value: '9:16',
                      child: Text('Portrait 9:16'),
                    ),
                    DropdownMenuItem(
                      value: '16:9',
                      child: Text('Landscape 16:9'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _aspect = value ?? '1:1'),
                ),
                DropdownButtonFormField<JewelryProcessingLook>(
                  initialValue: _look,
                  decoration: const InputDecoration(labelText: 'Jewelry filter'),
                  items: studioFilterLooks
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(jewelryProcessingLookLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(
                    () => _look = value ?? JewelryProcessingLook.luxuryDark,
                  ),
                ),
                DropdownButtonFormField<BackgroundTreatment>(
                  initialValue: _background,
                  decoration: const InputDecoration(labelText: 'Background'),
                  items: BackgroundTreatment.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(backgroundTreatmentLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(
                    () => _background = value ?? BackgroundTreatment.darkened,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Deep-black cut-out is not offered. Darkened uses a vignette grade and keeps the real product.',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: FilledButton(
                        onPressed: _save,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
