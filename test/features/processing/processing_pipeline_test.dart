import 'package:aig/features/processing/models/processing_context.dart';
import 'package:aig/features/processing/models/processing_result.dart';
import 'package:aig/features/processing/models/processing_session.dart';
import 'package:aig/features/processing/models/processing_state.dart';
import 'package:aig/features/processing/models/processing_stage.dart';
import 'package:aig/features/processing/pipeline/image_processing_pipeline.dart';
import 'package:aig/features/processing/processors/image_processor.dart';
import 'package:aig/features/processing/processors/placeholder_processors.dart';
import 'package:flutter_test/flutter_test.dart';

class TestProcessor extends ImageProcessor {
  TestProcessor({required super.name, required super.description});

  @override
  Future<ProcessingResult> process(ProcessingContext context) async {
    return ProcessingResult.success(
      stage: ProcessingStage.resize,
      session: context.session,
      message: 'ok',
      metadata: {'processed': true},
    );
  }
}

void main() {
  group('ImageProcessingPipeline', () {
    test('runs processors sequentially and updates progress', () async {
      final pipeline = ImageProcessingPipeline(
        processors: [
          TestProcessor(name: 'test-a', description: 'first'),
          TestProcessor(name: 'test-b', description: 'second'),
        ],
      );

      final session = ProcessingSession(
        id: 'session-1',
        sourceMediaId: 'media-1',
      );

      final result = await pipeline.run(session);

      expect(result.state, ProcessingState.completed);
      expect(result.session.appliedStages.length, 2);
      expect(result.session.progress, 1.0);
    });

    test('placeholder processors report an unavailable state instead of succeeding', () async {
      final pipeline = ImageProcessingPipeline(processors: [
        BackgroundRemovalProcessor(),
      ]);

      final session = ProcessingSession(id: 'session-2', sourceMediaId: 'media-2');
      final result = await pipeline.run(session);

      expect(result.state, ProcessingState.failed);
      expect(result.success, isFalse);
      expect(result.message, contains('unavailable'));
    });

    test('cancels when requested', () async {
      final pipeline = ImageProcessingPipeline(processors: [
        CancelableProcessor(),
      ]);

      final session = ProcessingSession(id: 'session-2', sourceMediaId: 'media-2');
      final result = await pipeline.run(session);

      expect(result.state, ProcessingState.cancelled);
    });
  });
}
