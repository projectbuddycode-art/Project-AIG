import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/features/processing/models/processing_session.dart';
import 'package:aig/features/processing/models/processing_stage.dart';
import 'package:aig/features/processing/models/processing_state.dart';
import 'package:aig/features/processing/providers/processing_providers.dart';

class DevProcessingScreen extends ConsumerStatefulWidget {
  const DevProcessingScreen({super.key});

  @override
  ConsumerState<DevProcessingScreen> createState() =>
      _DevProcessingScreenState();
}

class _DevProcessingScreenState extends ConsumerState<DevProcessingScreen> {
  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(pipelineStateNotifierProvider);
    final controller = ref.read(pipelineControllerProvider);
    final session = notifier.session;

    return Scaffold(
      appBar: AppBar(title: const Text('Dev Processing')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current stage: ${session.currentStage?.label ?? 'None'}'),
            Text('Progress: ${(session.progress * 100).toStringAsFixed(0)}%'),
            Text(
              'Elapsed time: ${session.startedAt == null ? 'n/a' : DateTime.now().difference(session.startedAt!).inSeconds}s',
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final processingSession = ProcessingSession(
                  id: 'demo',
                  sourceMediaId: 'media-demo',
                );
                final result = await ref
                    .read(processingPipelineProvider)
                    .run(processingSession);
                notifier.update(
                  processingSession.copyWith(
                    state: result.success
                        ? ProcessingState.completed
                        : ProcessingState.failed,
                    progress: 1.0,
                  ),
                );
              },
              child: const Text('Run'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => notifier.reset(),
              child: const Text('Cancel'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => controller.retry(session),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
