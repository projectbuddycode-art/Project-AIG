/// Represents the protocol-level response status returned by the device.
enum ResponseCode {
  success,
  failure,
  busy,
  timeout,
  unsupportedCommand,
  invalidPayload,
  invalidVersion,
  internalError,
}

extension ResponseCodeX on ResponseCode {
  String get description {
    switch (this) {
      case ResponseCode.success:
        return 'Success';
      case ResponseCode.failure:
        return 'Failure';
      case ResponseCode.busy:
        return 'Busy';
      case ResponseCode.timeout:
        return 'Timeout';
      case ResponseCode.unsupportedCommand:
        return 'Unsupported command';
      case ResponseCode.invalidPayload:
        return 'Invalid payload';
      case ResponseCode.invalidVersion:
        return 'Invalid version';
      case ResponseCode.internalError:
        return 'Internal error';
    }
  }
}
