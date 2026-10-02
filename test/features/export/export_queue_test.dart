import 'package:aig/features/export/models/export_configuration.dart';
import 'package:aig/features/export/models/export_job.dart';
import 'package:aig/features/export/models/export_queue.dart';
import 'package:aig/features/export/models/export_result.dart';
import 'package:aig/features/export/models/export_state.dart';
import 'package:aig/features/export/models/export_task.dart';
import 'package:flutter_test/flutter_test.dart';

class TestExportTask extends ExportTask {
  const TestExportTask({required super.id, required super.configuration});

  @override
  Future<ExportResult> execute() async {
    return ExportResult.success();
  }
}

void main() {
  group('ExportQueue', () {
    test('enqueues and processes jobs in order', () {
      final queue = ExportQueue();
      final first = ExportJob(
        id: 'job-1',
        task: TestExportTask(id: 'task-1', configuration: const ExportConfiguration()),
      );
      final second = ExportJob(
        id: 'job-2',
        task: TestExportTask(id: 'task-2', configuration: const ExportConfiguration()),
      );

      queue.enqueue(first);
      queue.enqueue(second);

      expect(queue.pendingJobs.length, 2);
      expect(queue.nextJob?.id, 'job-1');
    });

    test('can cancel and retry a queued job', () {
      final queue = ExportQueue();
      final job = ExportJob(
        id: 'job-3',
        task: TestExportTask(id: 'task-3', configuration: const ExportConfiguration()),
      );

      queue.enqueue(job);
      queue.cancel(job.id);

      expect(queue.pendingJobs, isEmpty);

      queue.retry(job.id);
      expect(queue.pendingJobs.single.id, 'job-3');
    });

    test('supports pause and resume state', () {
      final queue = ExportQueue();
      queue.pause();
      expect(queue.state, ExportState.preparing);

      queue.resume();
      expect(queue.state, ExportState.idle);
    });
  });
}
