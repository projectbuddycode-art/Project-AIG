import 'package:flutter/foundation.dart';

import 'package:aig/features/export/models/export_configuration.dart';
import 'package:aig/features/export/models/export_result.dart';

@immutable
abstract class ExportTask {
  const ExportTask({required this.id, required this.configuration});

  final String id;
  final ExportConfiguration configuration;

  Future<ExportResult> execute();
}
