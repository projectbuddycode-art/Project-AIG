import 'dart:async';
import 'dart:collection';

import 'package:aig/features/esp32/models/device_command.dart';
import 'package:aig/features/esp32/models/device_response.dart';
import 'package:aig/features/esp32/services/device_logger.dart';
import 'package:aig/features/esp32/services/device_protocol.dart';
import 'package:aig/features/esp32/services/device_transport.dart';

/// Manages command queueing, timeout, and sending over transport.
class CommandExecutor {
  final DeviceTransport _transport;
  final DeviceProtocol _protocol;
  final DeviceLogger _logger;
  final Duration timeout;

  final StreamController<DeviceResponse> _responseController = StreamController.broadcast();
  final Queue<_QueuedCommand> _queue = Queue();
  bool _isExecuting = false;

  CommandExecutor({
    required DeviceTransport transport,
    required DeviceProtocol protocol,
    required DeviceLogger logger,
    this.timeout = const Duration(seconds: 10),
  })  : _transport = transport,
        _protocol = protocol,
        _logger = logger;

  Stream<DeviceResponse> get responses => _responseController.stream;

  Future<void> enqueue(DeviceCommand command, {bool urgent = false}) async {
    final queued = _QueuedCommand(command);
    if (urgent) {
      _queue.addFirst(queued);
    } else {
      _queue.add(queued);
    }
    await _executeNext();
  }

  bool _isStopCommand(DeviceCommand command) {
    if (command.type != DeviceCommandType.rotation || command.payload.length < 2) {
      return false;
    }
    return command.payload[1] == 0x00 || command.payload[1] == 0xFF;
  }

  Future<void> _executeNext() async {
    if (_isExecuting || _queue.isEmpty) {
      return;
    }

    _isExecuting = true;
    final queued = _queue.removeFirst();
    final payload = _protocol.encode(queued.command);

    final completer = Completer<void>();
    late final StreamSubscription<List<int>> subscription;

    final timer = Timer(timeout, () {
      _logger.log('Command timeout: ${queued.command.type}');
      if (!completer.isCompleted) {
        completer.completeError(TimeoutException('Command timed out'));
      }
    });

    subscription = _transport.receive().listen(
      (data) {
        final response = _protocol.decode(data);
        _responseController.add(response);
        if (completer.isCompleted) {
          return;
        }
        if (response.type == DeviceResponseType.error) {
          completer.completeError(
            StateError('Machine rejected the command or is unreachable'),
          );
          return;
        }
        completer.complete();
        // After a successful acknowledgement for a non-status command,
        // enqueue a status sync to ensure UI reflects actual device state.
        try {
        if (response.type == DeviceResponseType.acknowledgement &&
            queued.command.type != DeviceCommandType.status &&
            !_isStopCommand(queued.command)) {
            // fire-and-forget enqueue; will run after current queue
            enqueue(DeviceCommand(type: DeviceCommandType.status));
          }
        } catch (e) {
          _logger.log('Failed to enqueue status sync: $e');
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
    );

    if (_isStopCommand(queued.command)) {
      await _transport.sendUrgent(payload);
    } else {
      await _transport.send(payload);
    }

    try {
      await completer.future;
    } finally {
      timer.cancel();
      await subscription.cancel();
      _isExecuting = false;
      await _executeNext();
    }
  }
}

class _QueuedCommand {
  final DeviceCommand command;

  _QueuedCommand(this.command);
}
