import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/features/capture/providers/capture_providers.dart';
import 'package:aig/features/capture/models/capture_session.dart';
import 'package:aig/features/capture/models/capture_mode.dart';
import 'package:aig/features/capture/models/capture_workflow_stage.dart';

class DevCaptureWorkflowScreen extends ConsumerWidget {
  const DevCaptureWorkflowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflowState = ref.watch(captureWorkflowStateProvider).value;
    final orchestrator = ref.read(captureOrchestratorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dev Capture Workflow')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stage: ${captureWorkflowStageLabel(workflowState?.stage, fallback: 'Idle')}',
            ),
            Text('State: ${workflowState?.currentStep ?? 'Idle'}'),
            Text('Running: ${workflowState?.isRunning ?? false}'),
            Text('Failed: ${workflowState?.hasFailed ?? false}'),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: workflowState?.progress.percent ?? 0,
            ),
            const SizedBox(height: 12),
            Text(
              'Progress: ${(workflowState?.progress.percent ?? 0.0 * 100).toStringAsFixed(0)}%',
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final session = CaptureSession(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  mode: CaptureMode.singlePhoto,
                );
                orchestrator.startSession(session);
              },
              child: const Text('Start'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => orchestrator.cancelSession(),
              child: const Text('Cancel'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => orchestrator.reset(),
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}
