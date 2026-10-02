import 'package:flutter/foundation.dart';

import 'package:aig/features/processing/models/processing_session.dart';

@immutable
class ProcessingContext {
  final ProcessingSession session;
  final Map<String, Object?> metadata;
  final bool isCancelled;

  const ProcessingContext({
    required this.session,
    this.metadata = const <String, Object?>{},
    this.isCancelled = false,
  });

  ProcessingContext copyWith({
    ProcessingSession? session,
    Map<String, Object?>? metadata,
    bool? isCancelled,
  }) {
    return ProcessingContext(
      session: session ?? this.session,
      metadata: metadata ?? this.metadata,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }
}
