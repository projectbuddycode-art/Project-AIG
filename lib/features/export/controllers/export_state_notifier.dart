import 'package:flutter/foundation.dart';

import 'package:aig/features/export/models/export_job.dart';
import 'package:aig/features/export/models/export_queue.dart';
import 'package:aig/features/export/models/export_state.dart';

class ExportStateNotifier extends ChangeNotifier {
  ExportStateNotifier({ExportQueue? queue}) : _queue = queue ?? ExportQueue();

  final ExportQueue _queue;

  ExportQueue get queue => _queue;

  ExportState get state => _queue.state;

  ExportJob? get currentJob => _queue.activeJob;

  List<ExportJob> get pendingJobs => _queue.pendingJobs;

  void refresh() {
    notifyListeners();
  }

  void updateQueue() {
    notifyListeners();
  }
}
