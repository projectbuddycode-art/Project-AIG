import 'package:aig/features/export/models/export_configuration.dart';
import 'package:aig/features/export/models/export_job.dart';
import 'package:aig/features/export/models/export_result.dart';
import 'package:aig/features/export/models/export_state.dart';
import 'package:aig/features/export/models/export_task.dart';

class ExportQueue {
  ExportQueue({List<ExportJob>? initialJobs}) : _pendingJobs = List<ExportJob>.from(initialJobs ?? <ExportJob>[]);

  final List<ExportJob> _pendingJobs;
  ExportState _state = ExportState.idle;
  ExportJob? _activeJob;

  List<ExportJob> get pendingJobs => List<ExportJob>.unmodifiable(_pendingJobs);
  ExportJob? get activeJob => _activeJob;
  ExportState get state => _state;
  ExportJob? get nextJob => _pendingJobs.isEmpty ? null : _pendingJobs.first;

  void enqueue(ExportJob job) {
    _pendingJobs.add(job);
    if (_state == ExportState.idle) {
      _state = ExportState.preparing;
    }
  }

  void cancel(String jobId) {
    _pendingJobs.removeWhere((job) => job.id == jobId);
    if (_activeJob?.id == jobId) {
      _activeJob = null;
    }
    _state = _pendingJobs.isEmpty ? ExportState.idle : ExportState.preparing;
  }

  void retry(String jobId) {
    final existing = _pendingJobs.where((job) => job.id == jobId);
    if (existing.isEmpty) {
      _pendingJobs.add(
        ExportJob(id: jobId, task: _activeJob?.task ?? const _UnavailableExportTask()),
      );
    }
    _state = ExportState.preparing;
  }

  void pause() {
    _state = ExportState.preparing;
  }

  void resume() {
    _state = _pendingJobs.isEmpty ? ExportState.idle : ExportState.preparing;
  }

  void markActive(ExportJob job) {
    _activeJob = job;
    _state = ExportState.exporting;
  }

  void completeActive(ExportJob job) {
    if (_activeJob?.id == job.id) {
      _activeJob = null;
    }
    _pendingJobs.removeWhere((candidate) => candidate.id == job.id);
    _state = _pendingJobs.isEmpty ? ExportState.completed : ExportState.preparing;
  }
}

class _UnavailableExportTask extends ExportTask {
  const _UnavailableExportTask() : super(id: 'unavailable', configuration: const ExportConfiguration());

  @override
  Future<ExportResult> execute() async {
    return ExportResult.failed(message: 'Unavailable export task');
  }
}
