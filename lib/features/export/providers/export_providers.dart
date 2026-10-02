import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/features/export/controllers/export_controller.dart';
import 'package:aig/features/export/controllers/export_state_notifier.dart';
import 'package:aig/features/export/models/export_engine.dart';
import 'package:aig/features/export/models/export_queue.dart';

final exportQueueProvider = Provider<ExportQueue>((ref) {
  return ExportQueue();
});

final exportEngineProvider = Provider<ExportEngine>((ref) {
  return ExportEngine();
});

final exportControllerProvider = Provider<ExportController>((ref) {
  return ExportController(queue: ref.read(exportQueueProvider));
});

final exportStateNotifierProvider = Provider<ExportStateNotifier>((ref) {
  return ExportStateNotifier(queue: ref.read(exportQueueProvider));
});
