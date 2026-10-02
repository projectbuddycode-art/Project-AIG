import 'package:flutter/foundation.dart';

import 'package:aig/features/esp32/models/error_code.dart';
import 'package:aig/features/esp32/models/response_code.dart';

@immutable
class ResponseDefinition {
  final ResponseCode responseCode;
  final ErrorCode? errorCode;
  final String name;
  final String description;

  const ResponseDefinition({
    required this.responseCode,
    this.errorCode,
    required this.name,
    this.description = '',
  });

  static const ResponseDefinition acknowledgement = ResponseDefinition(
    responseCode: ResponseCode.success,
    name: 'Acknowledgement',
    description: 'The device acknowledged command receipt.',
  );

  static const ResponseDefinition status = ResponseDefinition(
    responseCode: ResponseCode.success,
    name: 'Status',
    description: 'The device returned current status information.',
  );

  static const ResponseDefinition firmwareInfo = ResponseDefinition(
    responseCode: ResponseCode.success,
    name: 'Firmware Info',
    description: 'The device reported firmware metadata.',
  );

  static const ResponseDefinition diagnostics = ResponseDefinition(
    responseCode: ResponseCode.success,
    name: 'Diagnostics',
    description: 'The device returned diagnostics data.',
  );

  static const ResponseDefinition error = ResponseDefinition(
    responseCode: ResponseCode.failure,
    errorCode: ErrorCode.internalError,
    name: 'Error',
    description: 'The device returned a failure response.',
  );
}
