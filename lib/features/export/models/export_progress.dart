import 'package:flutter/foundation.dart';

@immutable
class ExportProgress {
  const ExportProgress({
    this.current = 0,
    this.total = 1,
    this.percent = 0.0,
  });

  final int current;
  final int total;
  final double percent;

  ExportProgress copyWith({int? current, int? total, double? percent}) {
    return ExportProgress(
      current: current ?? this.current,
      total: total ?? this.total,
      percent: percent ?? this.percent,
    );
  }
}
