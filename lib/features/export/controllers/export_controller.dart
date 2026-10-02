import 'package:aig/features/export/models/export_job.dart';
import 'package:aig/features/export/models/export_queue.dart';
import 'package:aig/features/export/models/export_session.dart';
import 'package:aig/features/export/models/export_state.dart';
import 'package:aig/features/export/models/export_task.dart';

class ExportController {
  ExportController({required ExportQueue queue}) : _queue = queue;

  final ExportQueue _queue;

  void enqueue(ExportJob job) {
    _queue.enqueue(job);
  }

  void cancel(String jobId) {
    _queue.cancel(jobId);
  }

  void retry(String jobId) {
    _queue.retry(jobId);
  }

  void pause() {
    _queue.pause();
  }

  void resume() {
    _queue.resume();
  }

  ExportSession buildSession(ExportTask task, {String? sourceMediaId}) {
    final metadata = <String, Object?>{
      'sourceMediaId': sourceMediaId,
      'sourceFilePath': task.configuration.metadata['sourceFilePath'],
      'title': task.configuration.metadata['title'],
    };

    return ExportSession(
      id: task.id,
      sourceMediaId: sourceMediaId,
      state: ExportState.preparing,
      configuration: task.configuration,
      metadata: metadata,
    );
  }
}
