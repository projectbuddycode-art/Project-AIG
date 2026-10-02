import 'package:aig/features/esp32/protocol/diamondcam_protocol.dart';

class MachineCommandParseResult {
  const MachineCommandParseResult({
    required this.stage,
    required this.message,
    this.success,
    this.payload,
  });

  final MachineCommandStage stage;
  final String message;
  final bool? success;
  final Map<String, dynamic>? payload;

  bool get accepted => stage == MachineCommandStage.accepted;
}
