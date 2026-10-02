import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aig/core/constants/app_constants.dart';
import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:aig/features/camera/preset_studio/models/camera_preset.dart';
import 'package:aig/features/camera/preset_studio/providers/preset_providers.dart';
import 'package:aig/features/preset/presentation/widgets/preset_app_bar.dart';
import 'package:aig/features/preset/presentation/widgets/preset_search_bar.dart';
import 'package:aig/features/preset/presentation/widgets/preset_categories.dart';
import 'package:aig/features/preset/presentation/widgets/preset_card.dart';
import 'package:aig/features/preset/presentation/widgets/preset_quick_actions.dart';
import 'package:aig/features/preset/presentation/widgets/preset_editor_sheet.dart';
import 'package:aig/features/preset/presentation/widgets/preset_empty_state.dart';

// presentation-only widgets for presets

class PresetStudioScreen extends ConsumerStatefulWidget {
  const PresetStudioScreen({super.key});

  @override
  ConsumerState<PresetStudioScreen> createState() => _PresetStudioScreenState();
}

class _PresetStudioScreenState extends ConsumerState<PresetStudioScreen> {
  String _search = '';
  String _activeCategory = 'All';

  List<String> get _categories => const [
    'All',
    'Diamond',
    'Ring',
    'Catalogue',
    'Instagram',
    'Custom',
  ];

  List<CameraPreset> _filtered(List<CameraPreset> presets) =>
      presets.where((p) {
        final byCategory = _mapPresetToCategory(p).toLowerCase();
        final matchCategory =
            _activeCategory.toLowerCase() == 'all' ||
            byCategory == _activeCategory.toLowerCase();
        final matchesSearch =
            _search.isEmpty ||
            p.name.toLowerCase().contains(_search.toLowerCase()) ||
            p.description.toLowerCase().contains(_search.toLowerCase());
        return matchCategory && matchesSearch;
      }).toList();

  String _mapPresetToCategory(CameraPreset p) {
    if (p.category.trim().isNotEmpty && p.category != 'Product') {
      return p.category.toLowerCase();
    }
    final id = p.id.toLowerCase();
    if (id.contains('diamond')) return 'diamond';
    if (id.contains('ring')) return 'ring';
    if (id.contains('social')) return 'instagram';
    if (p.isCustom) return 'custom';
    return 'catalogue';
  }

  Future<void> _openCreate({CameraPreset? initial}) async {
    final result = await showModalBottomSheet<CameraPreset>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
      builder: (_) => PresetEditorSheet(initial: initial),
    );
    if (!mounted || result == null) return;
    final error = await ref.read(presetCatalogProvider.notifier).upsert(result);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? 'Preset saved.')));
  }

  void _openDetails(CameraPreset preset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.xl,
            ),
            child: SingleChildScrollView(
              controller: controller,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'preset-hero-${preset.id}',
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryBackground,
                            borderRadius: BorderRadius.circular(
                              AppRadius.large,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              preset.isVideoPreset
                                  ? Icons.videocam
                                  : Icons.photo,
                              size: 48,
                              color: AppColors.accentGoldDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preset.name,
                              style: AppTypography.headline.copyWith(
                                fontSize: 20,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.s),
                            Text(
                              preset.description,
                              style: AppTypography.body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.s),
                            Wrap(
                              spacing: AppSpacing.m,
                              runSpacing: AppSpacing.xs,
                              children: [
                                Text(
                                  'Est. ${preset.captureDurationSeconds}s',
                                  style: AppTypography.label,
                                ),
                                Text(
                                  'Steps: ${preset.rotationConfig.steps}',
                                  style: AppTypography.label,
                                ),
                                Text(
                                  'Machine: Turntable Pro',
                                  style: AppTypography.label,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.s,
                    children: [
                      SizedBox(
                        width: 120,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.push(
                              AppRoutePath.cameraStudio,
                              extra: preset.id,
                            );
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: OutlinedButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(this.context);
                            Navigator.of(context).pop();
                            await ref
                                .read(presetCatalogProvider.notifier)
                                .duplicate(preset);
                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Preset duplicated.'),
                              ),
                            );
                          },
                          child: const Text('Duplicate'),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _openCreate(initial: preset);
                          },
                          child: const Text('Edit'),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: OutlinedButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(this.context);
                            Navigator.of(context).pop();
                            await ref
                                .read(presetCatalogProvider.notifier)
                                .delete(preset.id);
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  preset.isCustom
                                      ? 'Preset deleted.'
                                      : 'Built-in presets cannot be deleted.',
                                ),
                              ),
                            );
                          },
                          child: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.l),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Camera Card
                        _sectionCard(
                          'Camera',
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ISO: ${preset.cameraConfig.iso}',
                                style: AppTypography.label,
                              ),
                              Text(
                                'Aperture: ${preset.cameraConfig.aperture}',
                                style: AppTypography.label,
                              ),
                              Text(
                                'Shutter: 1/${(1.0 / preset.cameraConfig.shutterSpeed).round()}',
                                style: AppTypography.label,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        // Machine Card
                        _sectionCard(
                          'Machine',
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Speed: ${preset.machineSpeed}',
                                style: AppTypography.label,
                              ),
                              Text(
                                'Direction: ${preset.rotationDirection}',
                                style: AppTypography.label,
                              ),
                              Text(
                                'Required: ${preset.requiresMachine ? 'Yes' : 'No'}',
                                style: AppTypography.label,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        // Lighting Card
                        _sectionCard(
                          'Lighting',
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GPIO 33: ${preset.lightOn ? 'On' : 'Off'}',
                                style: AppTypography.label,
                              ),
                              Text(
                                'Intensity: ${preset.lightIntensity}',
                                style: AppTypography.label,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        // Processing Card
                        _sectionCard(
                          'Processing',
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preset.processingPipeline.join(', '),
                                style: AppTypography.label,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        // Export Card
                        _sectionCard(
                          'Export',
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Format: ${preset.exportDefaults.format}',
                                style: AppTypography.label,
                              ),
                              Text(
                                'Quality: ${(preset.exportDefaults.quality * 100).round()}%',
                                style: AppTypography.label,
                              ),
                              Text(
                                'Resolution: ${preset.exportDefaults.resolution}',
                                style: AppTypography.label,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        // Summary Card
                        _sectionCard(
                          'Summary',
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Capture Time: ${preset.captureDurationSeconds}s',
                                style: AppTypography.label,
                              ),
                              Text(
                                'Background: ${backgroundTreatmentLabel(preset.backgroundTreatment)}',
                                style: AppTypography.label,
                              ),
                              Text(
                                'Aspect: ${preset.aspectRatio}',
                                style: AppTypography.label,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final presets = _filtered(ref.watch(presetCatalogProvider));
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            PresetAppBar(onCreate: _openCreate),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                AppSpacing.s,
                AppSpacing.l,
                AppSpacing.s,
              ),
              child: PresetSearchBar(
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            PresetCategories(
              categories: _categories,
              active: _activeCategory,
              onSelected: (c) => setState(() => _activeCategory = c),
            ),
            const SizedBox(height: AppSpacing.s),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                child: presets.isEmpty
                    ? PresetEmptyState(onCreate: _openCreate)
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 720,
                              mainAxisExtent: 210,
                              crossAxisSpacing: AppSpacing.m,
                              mainAxisSpacing: AppSpacing.m,
                            ),
                        itemCount: presets.length,
                        itemBuilder: (context, index) {
                          final p = presets[index];
                          return GestureDetector(
                            onTap: () => _openDetails(p),
                            child: PresetCard(
                              preset: p,
                              category: _mapPresetToCategory(p),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const PresetQuickActions(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreate,
          label: const Text('New Preset'),
          icon: const Icon(Icons.add),
          backgroundColor: AppColors.accentGold,
        ),
      ),
    );
  }

  Widget _sectionCard(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadow.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.s),
          child,
        ],
      ),
    );
  }
}
