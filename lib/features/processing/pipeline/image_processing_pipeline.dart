import 'dart:async';

import 'package:aig/features/processing/models/processing_context.dart';
import 'package:aig/features/processing/models/processing_result.dart';
import 'package:aig/features/processing/models/processing_session.dart';
import 'package:aig/features/processing/models/processing_stage.dart';
import 'package:aig/features/processing/models/processing_state.dart';
import 'package:aig/features/processing/processors/image_processor.dart';

class ImageProcessingPipeline {
  ImageProcessingPipeline({required List<ImageProcessor> processors})
    : _processors = List<ImageProcessor>.unmodifiable(processors);

  final List<ImageProcessor> _processors;
  final StreamController<ProcessingSession> _sessionController =
      StreamController.broadcast();

  Stream<ProcessingSession> get sessionStream => _sessionController.stream;

  Future<ProcessingResult> run(ProcessingSession session) async {
    final start = DateTime.now();
    var current = session.copyWith(
      startedAt: start,
      currentStage: null,
      progress: 0.0,
      state: ProcessingState.preparing,
    );
    _sessionController.add(current);

    final context = ProcessingContext(session: current);
    for (final processor in _processors) {
      if (context.isCancelled) {
        current = current.copyWith(
          state: ProcessingState.cancelled,
          completedAt: DateTime.now(),
        );
        _sessionController.add(current);
        return ProcessingResult.cancelled(
          stage: ProcessingStage.resize,
          session: current,
        );
      }

      final stage = processor.stage ?? ProcessingStage.resize;
      current = current.copyWith(
        currentStage: stage,
        progress: _progressForIndex(
          _processors.indexOf(processor),
          _processors.length,
        ),
        state: ProcessingState.processing,
      );
      _sessionController.add(current);

      final result = await processor.process(
        context.copyWith(session: current),
      );
      final nextState = result.state == ProcessingState.cancelled
          ? ProcessingState.cancelled
          : result.success
          ? ProcessingState.processing
          : ProcessingState.failed;
      current = current.copyWith(
        appliedStages: <ProcessingStage>[...current.appliedStages, stage],
        progress: _progressForIndex(
          _processors.indexOf(processor) + 1,
          _processors.length,
        ),
        state: nextState,
        errors: result.success
            ? current.errors
            : <String>[...current.errors, result.message],
      );
      _sessionController.add(current);

      if (!result.success) {
        if (result.shouldRetry) {
          current = current.copyWith(
            state: ProcessingState.failed,
            completedAt: DateTime.now(),
          );
          _sessionController.add(current);
          return result;
        }
        current = current.copyWith(
          state: ProcessingState.failed,
          completedAt: DateTime.now(),
        );
        _sessionController.add(current);
        return result;
      }
    }

    current = current.copyWith(
      state: ProcessingState.completed,
      completedAt: DateTime.now(),
      progress: 1.0,
    );
    _sessionController.add(current);

    return ProcessingResult.success(
      stage: ProcessingStage.thumbnail,
      session: current,
    );
  }

  double _progressForIndex(int index, int total) {
    if (total <= 0) {
      return 0.0;
    }
    return (index / total).clamp(0.0, 1.0);
  }

  void dispose() {
    _sessionController.close();
  }
}
