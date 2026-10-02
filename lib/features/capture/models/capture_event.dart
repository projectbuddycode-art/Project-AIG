import 'package:flutter/foundation.dart';

/// Workflow events emitted by the capture orchestrator.
@immutable
class CaptureEvent {
  final String id;
  final String description;
  final DateTime timestamp;

  const CaptureEvent({
    required this.id,
    required this.description,
    required this.timestamp,
  });
}
