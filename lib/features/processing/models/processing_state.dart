enum ProcessingState {
  idle,
  preparing,
  processing,
  completed,
  cancelled,
  failed,
}

extension ProcessingStateX on ProcessingState {
  String get label {
    switch (this) {
      case ProcessingState.idle:
        return 'Idle';
      case ProcessingState.preparing:
        return 'Preparing';
      case ProcessingState.processing:
        return 'Processing';
      case ProcessingState.completed:
        return 'Completed';
      case ProcessingState.cancelled:
        return 'Cancelled';
      case ProcessingState.failed:
        return 'Failed';
    }
  }
}
