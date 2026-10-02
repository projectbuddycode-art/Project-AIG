import 'package:flutter/material.dart';
import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:aig/features/camera/preset_studio/models/camera_preset.dart';

class PresetCreateSheet extends StatefulWidget {
  const PresetCreateSheet({super.key});

  @override
  State<PresetCreateSheet> createState() => _PresetCreateSheetState();
}

class _PresetCreateSheetState extends State<PresetCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _category = 'Custom';
  final _description = TextEditingController();
  bool _favorite = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    // Build a presentation-only CameraPreset
    final preset = CameraPreset(
      id: _name.text.toLowerCase().replaceAll(' ', '-'),
      name: _name.text,
      description: _description.text,
    );
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Preset',
                style: AppTypography.headline.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppSpacing.m),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Preset Name'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: AppSpacing.s),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: const [
                  DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                  DropdownMenuItem(value: 'Diamond', child: Text('Diamond')),
                  DropdownMenuItem(value: 'Ring', child: Text('Ring')),
                  DropdownMenuItem(value: 'Bracelet', child: Text('Bracelet')),
                  DropdownMenuItem(value: 'Necklace', child: Text('Necklace')),
                  DropdownMenuItem(
                    value: 'Catalogue',
                    child: Text('Catalogue'),
                  ),
                  DropdownMenuItem(
                    value: 'Instagram',
                    child: Text('Instagram'),
                  ),
                ],
                onChanged: (v) => setState(() => _category = v ?? 'Custom'),
              ),
              const SizedBox(height: AppSpacing.s),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.s),
              Row(
                children: [
                  Checkbox(
                    value: _favorite,
                    onChanged: (v) => setState(() => _favorite = v ?? false),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Text('Favorite', style: AppTypography.label),
                ],
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
    );
  }
}
