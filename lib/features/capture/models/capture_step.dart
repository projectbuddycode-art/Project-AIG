import 'package:flutter/foundation.dart';

/// Represents the result of an individual capture step.
@immutable
class CaptureStepResult {
  final bool success;
  final String message;
  final bool shouldRetry;
  final bool isCritical;

  const CaptureStepResult({
    required this.success,
    this.message = '',
    this.shouldRetry = false,
    this.isCritical = true,
  });

  factory CaptureStepResult.success([String message = '']) =>
      CaptureStepResult(success: true, message: message);
  factory CaptureStepResult.failure(
    String message, {
    bool shouldRetry = false,
    bool isCritical = true,
  }) => CaptureStepResult(
    success: false,
    message: message,
    shouldRetry: shouldRetry,
    isCritical: isCritical,
  );
}

/// A single step inside a capture sequence.
class CaptureStep {
  final String id;
  final String name;
  final Duration? timeout;
  final Future<CaptureStepResult> Function() action;

  CaptureStep({
    required this.id,
    required this.name,
    required this.action,
    this.timeout,
  });
}
