import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/features/export/models/export_job.dart';
import 'package:aig/features/export/providers/export_providers.dart';

class DevExportMonitorScreen extends ConsumerWidget {
  const DevExportMonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(exportStateNotifierProvider);
    final queue = notifier.queue;

    return Scaffold(
      appBar: AppBar(title: const Text('Dev Export Monitor')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('State: ${queue.state.name}'),
            const SizedBox(height: 12),
            Text('Current job: ${queue.activeJob?.id ?? 'None'}'),
            const SizedBox(height: 12),
            Text('Queue (${queue.pendingJobs.length}):'),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: queue.pendingJobs.map((job) => _ExportJobTile(job: job)).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(onPressed: () => notifier.refresh(), child: const Text('Refresh')),
                ElevatedButton(onPressed: () => notifier.queue.pause(), child: const Text('Pause')),
                ElevatedButton(onPressed: () => notifier.queue.resume(), child: const Text('Resume')),
                ElevatedButton(onPressed: () => notifier.queue.cancel(queue.nextJob?.id ?? ''), child: const Text('Cancel')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportJobTile extends StatelessWidget {
  const _ExportJobTile({required this.job});

  final ExportJob job;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(job.id),
      subtitle: Text('State: ${job.state.name}'),
      trailing: Text('${job.progress.percent.toStringAsFixed(0)}%'),
    );
  }
}
