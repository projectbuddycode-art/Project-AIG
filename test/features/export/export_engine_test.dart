import 'dart:io';

import 'package:aig/features/export/models/export_configuration.dart';
import 'package:aig/features/export/models/export_engine.dart';
import 'package:aig/features/export/models/export_result.dart';
import 'package:aig/features/export/models/export_session.dart';
import 'package:aig/features/export/models/export_state.dart';
import 'package:aig/features/export/models/export_task.dart';
import 'package:flutter_test/flutter_test.dart';

class _InlineTask extends ExportTask {
  const _InlineTask({required super.id, required super.configuration});

  @override
  Future<ExportResult> execute() async {
    return ExportResult.failed(message: 'not used');
  }
}

void main() {
  group('ExportEngine', () {
    test('fails truthfully when no source file is provided', () async {
      final engine = ExportEngine();
      final task = _InlineTask(
        id: 'empty',
        configuration: const ExportConfiguration(),
      );
      final session = ExportSession(
        id: 'session-empty',
        state: ExportState.preparing,
        configuration: task.configuration,
        metadata: const <String, Object?>{},
      );

      final result = await engine.export(session, task);

      expect(result.state, ExportState.failed);
      expect(result.message, contains('No source file'));
    });

    test('fails truthfully when source path does not exist', () async {
      final engine = ExportEngine();
      final missing = '${Directory.systemTemp.path}/aig_missing_export_source.jpg';
      final task = _InlineTask(
        id: 'missing',
        configuration: ExportConfiguration(
          metadata: <String, Object?>{'sourceFilePath': missing},
        ),
      );
      final session = ExportSession(
        id: 'session-missing',
        state: ExportState.preparing,
        configuration: task.configuration,
        metadata: <String, Object?>{'sourceFilePath': missing},
      );

      final result = await engine.export(session, task);

      expect(result.state, ExportState.failed);
      expect(result.message, contains('no longer exists'));
    });
  });
}
