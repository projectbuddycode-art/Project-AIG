import 'package:flutter/foundation.dart';

/// Describes firmware-reported capabilities of an ESP32 device.
@immutable
class DeviceCapabilities {
  final bool rotation;
  final bool lighting;
  final bool cameraTrigger;
  final bool rgbLighting;
  final bool macroMode;
  final bool otaUpdates;
  final bool temperatureSensor;

  const DeviceCapabilities({
    this.rotation = false,
    this.lighting = false,
    this.cameraTrigger = false,
    this.rgbLighting = false,
    this.macroMode = false,
    this.otaUpdates = false,
    this.temperatureSensor = false,
  });

  DeviceCapabilities copyWith({
    bool? rotation,
    bool? lighting,
    bool? cameraTrigger,
    bool? rgbLighting,
    bool? macroMode,
    bool? otaUpdates,
    bool? temperatureSensor,
  }) {
    return DeviceCapabilities(
      rotation: rotation ?? this.rotation,
      lighting: lighting ?? this.lighting,
      cameraTrigger: cameraTrigger ?? this.cameraTrigger,
      rgbLighting: rgbLighting ?? this.rgbLighting,
      macroMode: macroMode ?? this.macroMode,
      otaUpdates: otaUpdates ?? this.otaUpdates,
      temperatureSensor: temperatureSensor ?? this.temperatureSensor,
    );
  }
}
