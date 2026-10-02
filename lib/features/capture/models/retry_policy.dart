import 'package:flutter/foundation.dart';

@immutable
class RetryPolicy {
  final int maxAttempts;
  final Duration backoff;

  const RetryPolicy({
    this.maxAttempts = 1,
    this.backoff = const Duration(seconds: 1),
  });

  bool get canRetry => maxAttempts > 1;
}
