enum ProcessingStage {
  backgroundRemoval,
  autoCrop,
  autoCenter,
  colorCorrection,
  whiteBalance,
  exposureCorrection,
  contrast,
  sharpness,
  noiseReduction,
  reflectionReduction,
  dustRemoval,
  watermark,
  resize,
  compression,
  thumbnail,
}

extension ProcessingStageX on ProcessingStage {
  String get label {
    switch (this) {
      case ProcessingStage.backgroundRemoval:
        return 'Background Removal';
      case ProcessingStage.autoCrop:
        return 'Auto Crop';
      case ProcessingStage.autoCenter:
        return 'Auto Center';
      case ProcessingStage.colorCorrection:
        return 'Color Correction';
      case ProcessingStage.whiteBalance:
        return 'White Balance';
      case ProcessingStage.exposureCorrection:
        return 'Exposure Correction';
      case ProcessingStage.contrast:
        return 'Contrast';
      case ProcessingStage.sharpness:
        return 'Sharpness';
      case ProcessingStage.noiseReduction:
        return 'Noise Reduction';
      case ProcessingStage.reflectionReduction:
        return 'Reflection Reduction';
      case ProcessingStage.dustRemoval:
        return 'Dust Removal';
      case ProcessingStage.watermark:
        return 'Watermark';
      case ProcessingStage.resize:
        return 'Resize';
      case ProcessingStage.compression:
        return 'Compression';
      case ProcessingStage.thumbnail:
        return 'Thumbnail';
    }
  }
}
