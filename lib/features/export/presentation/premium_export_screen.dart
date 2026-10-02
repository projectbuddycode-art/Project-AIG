import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:aig/core/constants/app_constants.dart';
import 'package:aig/features/gallery/models/media_item.dart';
import 'package:aig/features/gallery/models/media_type.dart';
import 'package:aig/features/export/presentation/widgets/export_app_bar.dart';
import 'package:aig/features/export/presentation/widgets/export_dashboard.dart';
import 'package:aig/features/export/presentation/widgets/export_summary_card.dart';
import 'package:aig/features/export/presentation/widgets/export_configuration_card.dart';
import 'package:aig/features/export/presentation/widgets/export_preview_card.dart';
import 'package:aig/features/export/presentation/widgets/export_queue_card.dart';
import 'package:aig/features/export/presentation/widgets/export_history_card.dart';
import 'package:aig/features/export/presentation/widgets/export_progress_card.dart';
import 'package:aig/features/export/providers/export_providers.dart';
import 'package:aig/features/export/controllers/export_controller.dart';
import 'package:aig/features/export/models/export_job.dart';
import 'package:aig/features/export/models/export_task.dart';
import 'package:aig/features/export/models/export_configuration.dart';
import 'package:aig/features/export/models/export_result.dart';
import 'package:aig/features/export/models/export_state.dart';
// export empty state widget available in widgets/

class PremiumExportScreen extends ConsumerStatefulWidget {
  const PremiumExportScreen({super.key, this.initialSelection});

  final List<MediaItem>? initialSelection;

  @override
  ConsumerState<PremiumExportScreen> createState() => _PremiumExportScreenState();
}

class _PremiumExportScreenState extends ConsumerState<PremiumExportScreen> {
  // local UI state for configuration (presentation-only)
  bool _enqueuedInitial = false;

  String _resolveExportSourcePath(MediaItem media) {
    final storage = media.storagePath;
    if (!storage.startsWith('content://')) {
      final file = File(storage);
      if (file.existsSync() && file.lengthSync() > 0) {
        return storage;
      }
    }
    final thumbnail = media.thumbnailPath;
    if (thumbnail != null && thumbnail.isNotEmpty) {
      final file = File(thumbnail);
      if (file.existsSync() && file.lengthSync() > 0) {
        return thumbnail;
      }
    }
    return storage;
  }
  void _enqueueInitialSelection(ExportController controller, List<MediaItem> selection) {
    for (final media in selection) {
      final sourcePath = _resolveExportSourcePath(media);
      final task = _InlineExportTask(
        id: media.id,
        configuration: ExportConfiguration(
          format: media.mediaType == MediaType.video ? ExportFormat.mp4 : ExportFormat.jpeg,
          filename: 'AIG_export',
          metadata: <String, Object?>{
            'sourceFilePath': sourcePath,
            'title': media.title,
          },
        ),
      );
      final job = ExportJob(
        id: task.id,
        task: task,
        metadata: {
          'mediaType': media.mediaType.name,
          'title': media.title,
          'sourceFilePath': sourcePath,
        },
      );
      controller.enqueue(job);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialSelection != null && widget.initialSelection!.isNotEmpty) {
      final controller = ref.read(exportControllerProvider);
      _enqueueInitialSelection(controller, widget.initialSelection!);
      _enqueuedInitial = true;
    }
  }

  void _showExportSuccessDialog(String outputPath) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Export Success'),
        content: Text('Exported to: $outputPath'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('OK')),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              GoRouter.of(dialogContext).push(AppRoutePath.gallery);
            },
            child: const Text('View Gallery'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const PreferredSize(preferredSize: Size.fromHeight(72), child: ExportAppBar()),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            children: [
              const ExportDashboard(),
              const SizedBox(height: AppSpacing.m),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: SingleChildScrollView(
                    key: const ValueKey('export_content'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SizedBox(height: AppSpacing.s),
                        ExportSummaryCard(),
                        SizedBox(height: AppSpacing.m),
                        ExportConfigurationCard(),
                        SizedBox(height: AppSpacing.m),
                        ExportPreviewCard(),
                        SizedBox(height: AppSpacing.m),
                        ExportQueueCard(),
                        SizedBox(height: AppSpacing.m),
                        ExportHistoryCard(),
                        SizedBox(height: AppSpacing.xl),
                        ExportProgressCard(),
                        SizedBox(height: AppSpacing.l),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.s, AppSpacing.l, AppSpacing.l),
          child: FilledButton.icon(
            onPressed: () async {
              final controller = ref.read(exportControllerProvider);
              final engine = ref.read(exportEngineProvider);
              final queue = ref.read(exportQueueProvider);

              if (!_enqueuedInitial && widget.initialSelection != null && widget.initialSelection!.isNotEmpty) {
                _enqueueInitialSelection(controller, widget.initialSelection!);
                _enqueuedInitial = true;
              }

              final jobs = List<ExportJob>.from(queue.pendingJobs);
              if (jobs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Select media in Gallery before exporting.')),
                );
                return;
              }

              ExportResult? lastResult;
              var allSucceeded = true;
              for (final job in jobs) {
                queue.markActive(job);
                final session = controller.buildSession(job.task, sourceMediaId: job.metadata['sourceMediaId'] as String?);
                lastResult = await engine.export(session, job.task);
                final output = lastResult.outputPath;
                final outputFile = output == null ? null : File(output);
                if (lastResult.state != ExportState.completed ||
                    output == null ||
                    output.isEmpty ||
                    outputFile == null ||
                    !outputFile.existsSync() ||
                    outputFile.lengthSync() <= 0) {
                  allSucceeded = false;
                  queue.completeActive(job);
                  continue;
                }
                queue.completeActive(job);
              }

              if (!context.mounted) {
                return;
              }

              if (!allSucceeded || lastResult?.state != ExportState.completed || lastResult?.outputPath == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(lastResult?.message ?? 'Export did not produce a file.')),
                );
                return;
              }

              _showExportSuccessDialog(lastResult!.outputPath!);
            },
            icon: const Icon(Icons.upload_outlined),
            label: const Text('EXPORT'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accentGold, minimumSize: const Size.fromHeight(56)),
          ),
        ),
      ),
    );
  }
}

class _InlineExportTask extends ExportTask {
  const _InlineExportTask({required super.id, required super.configuration});

  @override
  Future<ExportResult> execute() async {
    // Not used; ExportEngine.export is called directly by the screen integration.
    return ExportResult.failed(message: 'Inline task not executed.');
  }
}
