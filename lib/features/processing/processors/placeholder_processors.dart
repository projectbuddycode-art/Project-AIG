import 'package:aig/features/processing/models/processing_context.dart';
import 'package:aig/features/processing/models/processing_result.dart';
import 'package:aig/features/processing/models/processing_stage.dart';
import 'package:aig/features/processing/processors/image_processor.dart';

class BackgroundRemovalProcessor extends ImageProcessor {
  const BackgroundRemovalProcessor()
    : super(
        name: 'Background Removal',
        description: 'Deterministic background pass',
        stage: ProcessingStage.backgroundRemoval,
      );

  @override
  Future<ProcessingResult> process(ProcessingContext context) async {
    return _unavailable(
      context,
      ProcessingStage.backgroundRemoval,
      'Background removal is unavailable in this build',
    );
  }
}

class AutoCropProcessor extends ImageProcessor {
  const AutoCropProcessor()
    : super(
        name: 'Auto Crop',
        description: 'Deterministic auto crop',
        stage: ProcessingStage.autoCrop,
      );

  @override
  Future<ProcessingResult> process(ProcessingContext context) async {
    return _unavailable(
      context,
      ProcessingStage.autoCrop,
      'Auto crop is unavailable in this build',
    );
  }
}

class AutoCenterProcessor extends ImageProcessor {
  const AutoCenterProcessor()
    : super(
        name: 'Auto Center',
        description: 'Deterministic auto-center crop',
        stage: ProcessingStage.autoCenter,
      );

  @override
  Future<ProcessingResult> process(ProcessingContext context) async {
    return _unavailable(
      context,
      ProcessingStage.autoCenter,
      'Auto center is unavailable in this build',
    );
  }
}

class ColorCorrectionProcessor extends ImageProcessor {
  const ColorCorrectionProcessor()
    : super(
        name: 'Color Correction',
        description: 'Deterministic color correction',
        stage: ProcessingStage.colorCorrection,
      );

  @override
  Future<ProcessingResult> process(ProcessingContext context) async {
    return _unavailable(
      context,
      ProcessingStage.colorCorrection,
      'Color correction is unavailable in this build',
    );
  }
}

class WhiteBalanceProcessor extends ImageProcessor {
  const WhiteBalanceProcessor()
    : super(
        name: 'White Balance',
        description: 'Deterministic white balance',
        stage: ProcessingStage.whiteBalance,
      );

  @override
  Future<ProcessingResult> process(ProcessingContext context) async {
    return _unavailable(
      context,
      ProcessingStage.whiteBalance,
      'White balance is unavailable in this build',
    );
  }
}

class ExposureCorrectionProcessor extends ImageProcessor {
  const ExposureCorrectionProcessor()
    : super(
        name: 'Exposure Correction',
        description: 'Deterministic exposure correction',
        stage: ProcessingStage.exposureCorrection,
      );

  @override
  Future<ProcessingResult> process(ProcessingContext context) async {
    return _unavailable(
      context,
      ProcessingStage.exposureCorrection,
      'Exposure correction is unavailable in this build',
    );
  }
}

class ContrastProcessor extends ImageProcessor {
  const ContrastProcessor()
    : super(
        name: 'Contrast',
        description: 'Deterministic contrast adjustment',
        stage: ProcessingStage.contrast,
      );

  @override
  Future<ProcessingResult> process(ProcessingContext context) async {
    return _unavailable(
      context,
      ProcessingStage.contrast,
      'Contrast adjustment is unavailable in this build',
    );
  }
}

class SharpnessProcessor extends ImageProcessor {
  const SharpnessProcessor()
    : super(
        name: 'Sharpness',
        description: 'Deterministic sharpness pass',
        stage: ProcessingStage.sharpness,
      );

  @override
  Future<ProcessingResult> process(ProcessingContext context) async {
    return _unavailable(
      context,
      ProcessingStage.sharpness,
      'Sharpness processing is unavailable in this build',
    );
  }
}

class NoiseReductionProcessor extends ImageProcessor {
  const NoiseReductionProcessor()
    : super(
        name: 'Noise Reduction',
        description: 'Deterministic noise reduction',
        stage: ProcessingStage.noiseReduction,
      );

  @override
  Future<ProcessingResult> process(ProcessingContext context) async {
    return _unavailable(
      context,
      ProcessingStage.noiseReduction,
      'Noise reduction is unavailable in this build',
    );
  }
}

class ReflectionReductionProcessor extends ImageProcessor {
  const ReflectionReductionProcessor()
    : super(
        name: 'Reflection Reduction',
        description: 'Deterministic reflection reduction',
        stage: ProcessingStage.reflectionReduction,
      );

  @override
  Future<ProcessingResult> process(ProcessingContext context) async {
    return _unavailable(
      context,
      ProcessingStage.reflectionReduction,
      'Reflection reduction is unavailable in this build',
    );
  }
}

class DustRemovalProcessor extends ImageProcessor {
  const DustRemovalProcessor()
    : super(
        name: 'Dust Removal',
        description: 'Deterministic dust removal',
        stage: ProcessingStage.dustRemoval,
      );

  @override
  Future<ProcessingResult> process(ProcessingContext context) async {
    return _unavailable(
      context,
      ProcessingStage.dustRemoval,
      'Dust removal is unavailable in this build',
    );
  }
}

class WatermarkProcessor extends ImageProcessor {
  const WatermarkProcessor()
    : super(
        name: 'Watermark',
        description: 'Deterministic watermark pass',
        stage: ProcessingStage.watermark,
      );

  @override
  Future<ProcessingResult> process(ProcessingContext context) async {
    return _unavailable(
      context,
      ProcessingStage.watermark,
      'Watermark processing is unavailable in this build',
    );
  }
}

class ResizeProcessor extends ImageProcessor {
  const ResizeProcessor()
    : super(
        name: 'Resize',
        description: 'Deterministic resize',
        stage: ProcessingStage.resize,
      );

  @override
  Future<ProcessingResult> process(ProcessingContext context) async {
    return _unavailable(
      context,
      ProcessingStage.resize,
      'Resize processing is unavailable in this build',
    );
  }
}

class CompressionProcessor extends ImageProcessor {
  const CompressionProcessor()
    : super(
        name: 'Compression',
        description: 'Deterministic compression',
        stage: ProcessingStage.compression,
      );

  @override
  Future<ProcessingResult> process(ProcessingContext context) async {
    return _unavailable(
      context,
      ProcessingStage.compression,
      'Compression is unavailable in this build',
    );
  }
}

class ThumbnailProcessor extends ImageProcessor {
  const ThumbnailProcessor()
    : super(
        name: 'Thumbnail',
        description: 'Deterministic thumbnail generation',
        stage: ProcessingStage.thumbnail,
      );

  @override
  Future<ProcessingResult> process(ProcessingContext context) async {
    return _unavailable(
      context,
      ProcessingStage.thumbnail,
      'Thumbnail generation is unavailable in this build',
    );
  }
}

class CancelableProcessor extends ImageProcessor {
  const CancelableProcessor()
    : super(
        name: 'Cancel',
        description: 'Cancels the pipeline',
        stage: ProcessingStage.resize,
      );

  @override
  Future<ProcessingResult> process(ProcessingContext context) async {
    return ProcessingResult.cancelled(
      stage: ProcessingStage.resize,
      session: context.session,
      message: 'Cancelled',
    );
  }
}

ProcessingResult _unavailable(
  ProcessingContext context,
  ProcessingStage stage,
  String message,
) {
  return ProcessingResult.failure(
    stage: stage,
    session: context.session,
    message: message,
  );
}
