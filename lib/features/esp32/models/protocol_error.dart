import 'package:flutter/foundation.dart';

import 'package:aig/features/esp32/models/error_code.dart';

@immutable
class ProtocolException implements Exception {
  final ErrorCode code;
  final String message;

  const ProtocolException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'ProtocolException(code: $code, message: $message)';
}
