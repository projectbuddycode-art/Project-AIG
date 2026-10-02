import 'package:aig/features/processing/models/processing_result.dart';
import 'package:aig/features/processing/models/processing_session.dart';
import 'package:aig/features/processing/models/processing_state.dart';
import 'package:aig/features/processing/pipeline/image_processing_pipeline.dart';

class PipelineController {
  PipelineController({required ImageProcessingPipeline pipeline})
    : _pipeline = pipeline;

  final ImageProcessingPipeline _pipeline;

  Future<ProcessingResult> run(ProcessingSession session) async {
    return _pipeline.run(session);
  }

  Future<void> cancel() async {}

  Future<ProcessingResult> retry(ProcessingSession session) async {
    return _pipeline.run(session.copyWith(state: ProcessingState.idle));
  }
}
