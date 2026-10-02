import 'package:flutter/foundation.dart';

enum MachineRotationMode { none, continuous, angle }

enum JewelryProcessingLook {
  original,
  luxuryDark,
  premiumShowcase,
  ecommerceNeutral,
  socialPortrait,
  gemstoneCloseup,
  slowElegant,
  coolStudio,
  highContrast,
}

enum BackgroundTreatment { original, darkened }

String backgroundTreatmentLabel(BackgroundTreatment value) {
  switch (value) {
    case BackgroundTreatment.original:
      return 'Original background';
    case BackgroundTreatment.darkened:
      return 'Darkened (not cut-out)';
  }
}

@immutable
class CameraPreset {
  const CameraPreset({
    required this.id,
    required this.name,
    required this.description,
    this.advertisingPurpose = 'Product capture',
    this.cameraConfig = const CameraConfig(),
    this.lightingConfig = const LightingConfig(),
    this.rotationConfig = const RotationConfig(),
    this.captureDurationSeconds = 5,
    this.processingPipeline = const <String>['resize', 'thumbnail'],
    this.exportDefaults = const ExportDefaults(),
    this.isVideoPreset = false,
    this.requiresMachine = false,
    this.rotationMode = MachineRotationMode.none,
    this.rotationDirection = 'cw',
    this.machineSpeed = 30,
    this.machineAngle,
    this.lightOn = true,
    this.lightIntensity = 80,
    this.aspectRatio = '16:9',
    this.frameRate = 30,
    this.resolutionLabel = 'source',
    this.processingLook = JewelryProcessingLook.original,
    this.isCustom = false,
    this.category = 'Product',
    this.backgroundTreatment = BackgroundTreatment.darkened,
    this.allowUpscale = false,
    this.filterStrength = 70,
  });

  final String id;
  final String name;
  final String description;
  final String advertisingPurpose;
  final CameraConfig cameraConfig;
  final LightingConfig lightingConfig;
  final RotationConfig rotationConfig;
  final int captureDurationSeconds;
  final List<String> processingPipeline;
  final ExportDefaults exportDefaults;
  final bool isVideoPreset;
  final bool requiresMachine;
  final MachineRotationMode rotationMode;
  final String rotationDirection;
  final int machineSpeed;
  final double? machineAngle;
  final bool lightOn;
  final int lightIntensity;
  final String aspectRatio;
  final int frameRate;
  final String resolutionLabel;
  final JewelryProcessingLook processingLook;
  final bool isCustom;
  final String category;
  final BackgroundTreatment backgroundTreatment;
  final bool allowUpscale;
  final int filterStrength;

  bool get usesContinuousRotation =>
      rotationMode == MachineRotationMode.continuous ||
      rotationConfig.autoRotate;

  CameraPreset copyWith({
    String? id,
    String? name,
    String? description,
    String? advertisingPurpose,
    CameraConfig? cameraConfig,
    LightingConfig? lightingConfig,
    RotationConfig? rotationConfig,
    int? captureDurationSeconds,
    List<String>? processingPipeline,
    ExportDefaults? exportDefaults,
    bool? isVideoPreset,
    bool? requiresMachine,
    MachineRotationMode? rotationMode,
    String? rotationDirection,
    int? machineSpeed,
    double? machineAngle,
    bool? lightOn,
    int? lightIntensity,
    String? aspectRatio,
    int? frameRate,
    String? resolutionLabel,
    JewelryProcessingLook? processingLook,
    bool? isCustom,
    String? category,
    BackgroundTreatment? backgroundTreatment,
    bool? allowUpscale,
    int? filterStrength,
  }) {
    return CameraPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      advertisingPurpose: advertisingPurpose ?? this.advertisingPurpose,
      cameraConfig: cameraConfig ?? this.cameraConfig,
      lightingConfig: lightingConfig ?? this.lightingConfig,
      rotationConfig: rotationConfig ?? this.rotationConfig,
      captureDurationSeconds:
          captureDurationSeconds ?? this.captureDurationSeconds,
      processingPipeline: processingPipeline ?? this.processingPipeline,
      exportDefaults: exportDefaults ?? this.exportDefaults,
      isVideoPreset: isVideoPreset ?? this.isVideoPreset,
      requiresMachine: requiresMachine ?? this.requiresMachine,
      rotationMode: rotationMode ?? this.rotationMode,
      rotationDirection: rotationDirection ?? this.rotationDirection,
      machineSpeed: machineSpeed ?? this.machineSpeed,
      machineAngle: machineAngle ?? this.machineAngle,
      lightOn: lightOn ?? this.lightOn,
      lightIntensity: lightIntensity ?? this.lightIntensity,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      frameRate: frameRate ?? this.frameRate,
      resolutionLabel: resolutionLabel ?? this.resolutionLabel,
      processingLook: processingLook ?? this.processingLook,
      isCustom: isCustom ?? this.isCustom,
      category: category ?? this.category,
      backgroundTreatment: backgroundTreatment ?? this.backgroundTreatment,
      allowUpscale: allowUpscale ?? this.allowUpscale,
      filterStrength: filterStrength ?? this.filterStrength,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'description': description,
      'advertisingPurpose': advertisingPurpose,
      'captureDurationSeconds': captureDurationSeconds,
      'processingPipeline': processingPipeline,
      'isVideoPreset': isVideoPreset,
      'requiresMachine': requiresMachine,
      'rotationMode': rotationMode.name,
      'rotationDirection': rotationDirection,
      'machineSpeed': machineSpeed,
      'machineAngle': machineAngle,
      'lightOn': lightOn,
      'lightIntensity': lightIntensity,
      'aspectRatio': aspectRatio,
      'frameRate': frameRate,
      'resolutionLabel': resolutionLabel,
      'processingLook': processingLook.name,
      'isCustom': isCustom,
      'category': category,
      'backgroundTreatment': backgroundTreatment.name,
      'allowUpscale': allowUpscale,
      'filterStrength': filterStrength,
      'cameraConfig': <String, Object?>{
        'iso': cameraConfig.iso,
        'shutterSpeed': cameraConfig.shutterSpeed,
        'aperture': cameraConfig.aperture,
        'whiteBalance': cameraConfig.whiteBalance,
      },
      'lightingConfig': <String, Object?>{
        'brightness': lightingConfig.brightness,
        'temperature': lightingConfig.temperature,
        'softness': lightingConfig.softness,
      },
      'rotationConfig': <String, Object?>{
        'steps': rotationConfig.steps,
        'speed': rotationConfig.speed,
        'autoRotate': rotationConfig.autoRotate,
      },
      'exportDefaults': <String, Object?>{
        'format': exportDefaults.format,
        'quality': exportDefaults.quality,
        'resolution': exportDefaults.resolution,
      },
    };
  }

  factory CameraPreset.fromJson(Map<String, dynamic> json) {
    CameraConfig camera = const CameraConfig();
    final cameraJson = json['cameraConfig'];
    if (cameraJson is Map) {
      camera = CameraConfig(
        iso: (cameraJson['iso'] as num?)?.round() ?? 100,
        shutterSpeed:
            (cameraJson['shutterSpeed'] as num?)?.toDouble() ?? 1.0 / 125.0,
        aperture: (cameraJson['aperture'] as num?)?.toDouble() ?? 2.8,
        whiteBalance: cameraJson['whiteBalance'] as String? ?? 'auto',
      );
    }
    LightingConfig lighting = const LightingConfig();
    final lightingJson = json['lightingConfig'];
    if (lightingJson is Map) {
      lighting = LightingConfig(
        brightness: (lightingJson['brightness'] as num?)?.toDouble() ?? 0.75,
        temperature: (lightingJson['temperature'] as num?)?.round() ?? 5600,
        softness: (lightingJson['softness'] as num?)?.toDouble() ?? 0.6,
      );
    }
    RotationConfig rotation = const RotationConfig();
    final rotationJson = json['rotationConfig'];
    if (rotationJson is Map) {
      rotation = RotationConfig(
        steps: (rotationJson['steps'] as num?)?.round() ?? 36,
        speed: (rotationJson['speed'] as num?)?.toDouble() ?? 1.0,
        autoRotate: rotationJson['autoRotate'] as bool? ?? true,
      );
    }
    ExportDefaults export = const ExportDefaults();
    final exportJson = json['exportDefaults'];
    if (exportJson is Map) {
      export = ExportDefaults(
        format: exportJson['format'] as String? ?? 'mp4',
        quality: (exportJson['quality'] as num?)?.toDouble() ?? 0.92,
        resolution: exportJson['resolution'] as String? ?? '1080p',
      );
    }
    return CameraPreset(
      id: json['id'] as String? ?? 'preset',
      name: json['name'] as String? ?? 'Preset',
      description: json['description'] as String? ?? '',
      advertisingPurpose:
          json['advertisingPurpose'] as String? ?? 'Product capture',
      cameraConfig: camera,
      lightingConfig: lighting,
      rotationConfig: rotation,
      captureDurationSeconds:
          (json['captureDurationSeconds'] as num?)?.round() ?? 8,
      processingPipeline:
          (json['processingPipeline'] as List?)?.cast<String>() ??
          const <String>['validate', 'grade', 'export'],
      exportDefaults: export,
      isVideoPreset: json['isVideoPreset'] as bool? ?? true,
      requiresMachine: json['requiresMachine'] as bool? ?? false,
      rotationMode: MachineRotationMode.values.firstWhere(
        (value) => value.name == json['rotationMode'],
        orElse: () => MachineRotationMode.none,
      ),
      rotationDirection: json['rotationDirection'] as String? ?? 'cw',
      machineSpeed: (json['machineSpeed'] as num?)?.round() ?? 30,
      machineAngle: (json['machineAngle'] as num?)?.toDouble(),
      lightOn: json['lightOn'] as bool? ?? true,
      lightIntensity: (json['lightIntensity'] as num?)?.round() ?? 80,
      aspectRatio: json['aspectRatio'] as String? ?? '1:1',
      frameRate: (json['frameRate'] as num?)?.round() ?? 30,
      resolutionLabel: json['resolutionLabel'] as String? ?? 'source',
      processingLook: JewelryProcessingLook.values.firstWhere(
        (value) => value.name == json['processingLook'],
        orElse: () => JewelryProcessingLook.luxuryDark,
      ),
      isCustom: json['isCustom'] as bool? ?? true,
      category: json['category'] as String? ?? 'Custom',
      backgroundTreatment: BackgroundTreatment.values.firstWhere(
        (value) => value.name == json['backgroundTreatment'],
        orElse: () => BackgroundTreatment.darkened,
      ),
      allowUpscale: json['allowUpscale'] as bool? ?? false,
      filterStrength: (json['filterStrength'] as num?)?.round() ?? 70,
    );
  }
}

@immutable
class CameraConfig {
  const CameraConfig({
    this.iso = 100,
    this.shutterSpeed = 1.0 / 125.0,
    this.aperture = 2.8,
    this.whiteBalance = 'auto',
  });

  final int iso;
  final double shutterSpeed;
  final double aperture;
  final String whiteBalance;
}

@immutable
class LightingConfig {
  const LightingConfig({
    this.brightness = 0.75,
    this.temperature = 5600,
    this.softness = 0.6,
  });

  final double brightness;
  final int temperature;
  final double softness;
}

@immutable
class RotationConfig {
  const RotationConfig({
    this.steps = 36,
    this.speed = 1.0,
    this.autoRotate = true,
  });

  final int steps;
  final double speed;
  final bool autoRotate;
}

@immutable
class ExportDefaults {
  const ExportDefaults({
    this.format = 'mp4',
    this.quality = 0.92,
    this.resolution = '1080p',
  });

  final String format;
  final double quality;
  final String resolution;
}
