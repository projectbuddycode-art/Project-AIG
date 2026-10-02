import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/features/processing/controllers/pipeline_controller.dart';
import 'package:aig/features/processing/controllers/pipeline_state_notifier.dart';
import 'package:aig/features/processing/pipeline/image_processing_pipeline.dart';
import 'package:aig/features/processing/processors/placeholder_processors.dart';

final processingPipelineProvider = Provider<ImageProcessingPipeline>((ref) {
  return ImageProcessingPipeline(
    processors: const [
      BackgroundRemovalProcessor(),
      AutoCropProcessor(),
      AutoCenterProcessor(),
      ColorCorrectionProcessor(),
      WhiteBalanceProcessor(),
      ExposureCorrectionProcessor(),
      ContrastProcessor(),
      SharpnessProcessor(),
      NoiseReductionProcessor(),
      ReflectionReductionProcessor(),
      DustRemovalProcessor(),
      WatermarkProcessor(),
      ResizeProcessor(),
      CompressionProcessor(),
      ThumbnailProcessor(),
    ],
  );
});

final pipelineControllerProvider = Provider<PipelineController>((ref) {
  return PipelineController(pipeline: ref.read(processingPipelineProvider));
});

final pipelineStateNotifierProvider = Provider<PipelineStateNotifier>((ref) {
  return PipelineStateNotifier();
});
