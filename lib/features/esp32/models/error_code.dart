/// Describes error conditions returned by the device protocol.
enum ErrorCode {
  none,
  unknownCommand,
  malformedPayload,
  invalidCommand,
  invalidState,
  protocolMismatch,
  timeout,
  unsupportedFeature,
  internalError,
}

extension ErrorCodeX on ErrorCode {
  String get description {
    switch (this) {
      case ErrorCode.none:
        return 'No error';
      case ErrorCode.unknownCommand:
        return 'Unknown command';
      case ErrorCode.malformedPayload:
        return 'Malformed payload';
      case ErrorCode.invalidCommand:
        return 'Invalid command';
      case ErrorCode.invalidState:
        return 'Invalid state for command';
      case ErrorCode.protocolMismatch:
        return 'Protocol version mismatch';
      case ErrorCode.timeout:
        return 'Operation timed out';
      case ErrorCode.unsupportedFeature:
        return 'Unsupported feature';
      case ErrorCode.internalError:
        return 'Internal device error';
    }
  }
}
