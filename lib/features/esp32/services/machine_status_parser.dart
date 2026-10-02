import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:aig/features/esp32/models/machine_command_result.dart';
import 'package:aig/features/esp32/models/machine_info.dart';
import 'package:aig/features/esp32/protocol/diamondcam_protocol.dart';

class MachineStatusParseResult {
  const MachineStatusParseResult({
    required this.accepted,
    required this.firmwareVersion,
    required this.identityReason,
    this.payload,
    this.connected,
    this.rotation,
    this.light,
    this.intensity,
    this.motorRunning,
    this.presentKeys = const [],
    this.rawBody,
  });

  final bool accepted;
  final String? firmwareVersion;
  final String identityReason;
  final Map<String, dynamic>? payload;
  final bool? connected;
  final num? rotation;
  final dynamic light;
  final num? intensity;
  final bool? motorRunning;
  final List<String> presentKeys;
  final String? rawBody;
}

/// Parses DiamondCam JSON. Required /status keys are checked with containsKey
/// after canonicalization. false / 0 are valid values.
class MachineStatusParser {
  static const requiredKeys = DiamondCamProtocol.requiredStatusKeys;

  MachineStatusParseResult parse(String body) {
    final trimmed = _stripBom(body).trim();
    _log('REQUEST/STATUS parse begin length=${body.length}');
    _log('RAW RESPONSE BODY: $trimmed');

    if (trimmed.isEmpty) {
      return MachineStatusParseResult(
        accepted: false,
        firmwareVersion: null,
        identityReason: 'Empty status body',
        rawBody: body,
      );
    }
    if (trimmed.toLowerCase().contains('<html')) {
      return MachineStatusParseResult(
        accepted: false,
        firmwareVersion: null,
        identityReason: 'Status body was HTML, not a machine payload',
        rawBody: trimmed,
      );
    }

    try {
      final decoded = _decodeJsonPossiblyTwice(trimmed);
      _log('DECODED JSON type=${decoded.runtimeType} value=$decoded');

      if (decoded is! Map) {
        return MachineStatusParseResult(
          accepted: false,
          firmwareVersion: null,
          identityReason: 'Status JSON was not an object (got ${decoded.runtimeType})',
          rawBody: trimmed,
        );
      }

      final root = _stringKeyedMap(decoded);
      final payload = _extractStatusObject(root);
      final present = payload.keys.map((k) => k.toString()).toList();
      _log('MODEL MAPPING keys=$present');

      final missing = requiredKeys.where((key) => !payload.containsKey(key)).toList();
      if (missing.isNotEmpty) {
        final reason =
            'Missing required /status keys: ${missing.join(', ')}. Present keys: ${present.isEmpty ? '(none)' : present.join(', ')}. Raw: ${_clip(trimmed)}';
        _log('VALIDATION RESULT rejected $reason');
        return MachineStatusParseResult(
          accepted: false,
          firmwareVersion: null,
          identityReason: reason,
          payload: payload,
          presentKeys: present,
          rawBody: trimmed,
        );
      }

      final connected = _asBool(payload['connected']);
      if (connected == null) {
        return MachineStatusParseResult(
          accepted: false,
          firmwareVersion: null,
          identityReason: 'Field connected must be boolean (false is valid)',
          payload: payload,
          presentKeys: present,
          rawBody: trimmed,
        );
      }
      final rotation = _asNum(payload['rotation']);
      if (rotation == null) {
        return MachineStatusParseResult(
          accepted: false,
          firmwareVersion: null,
          identityReason: 'Field rotation must be numeric (0 is valid; commanded angle, not measured)',
          payload: payload,
          presentKeys: present,
          rawBody: trimmed,
        );
      }
      if (!payload.containsKey('light')) {
        return MachineStatusParseResult(
          accepted: false,
          firmwareVersion: null,
          identityReason: 'Missing required /status keys: light',
          payload: payload,
          presentKeys: present,
          rawBody: trimmed,
        );
      }
      final intensity = _asNum(payload['intensity']);
      if (intensity == null) {
        return MachineStatusParseResult(
          accepted: false,
          firmwareVersion: null,
          identityReason: 'Field intensity must be numeric (0 is valid)',
          payload: payload,
          presentKeys: present,
          rawBody: trimmed,
        );
      }
      final motorRunning = _asBool(payload['motorRunning']);
      if (motorRunning == null) {
        return MachineStatusParseResult(
          accepted: false,
          firmwareVersion: null,
          identityReason: 'Field motorRunning must be boolean (false is valid)',
          payload: payload,
          presentKeys: present,
          rawBody: trimmed,
        );
      }

      _log('VALIDATION RESULT accepted connected=$connected rotation=$rotation light=${payload['light']} intensity=$intensity motorRunning=$motorRunning');
      return MachineStatusParseResult(
        accepted: true,
        firmwareVersion: null,
        identityReason: 'DiamondCam /status contract matched',
        payload: payload,
        connected: connected,
        rotation: rotation,
        light: payload['light'],
        intensity: intensity,
        motorRunning: motorRunning,
        presentKeys: present,
        rawBody: trimmed,
      );
    } catch (_) {
      return MachineStatusParseResult(
        accepted: false,
        firmwareVersion: null,
        identityReason: 'Status body was not valid JSON. Raw: ${_clip(trimmed)}',
        rawBody: trimmed,
      );
    }
  }

  MachineCommandParseResult parseCommand(int statusCode, String body) {
    if (statusCode < 200 || statusCode >= 300) {
      return MachineCommandParseResult(
        stage: MachineCommandStage.httpError,
        message: 'HTTP $statusCode. Body: ${_clip(body)}',
      );
    }
    final trimmed = _stripBom(body).trim();
    if (trimmed.isEmpty) {
      return const MachineCommandParseResult(
        stage: MachineCommandStage.invalidJson,
        message: 'HTTP success but empty response body (success=true is required)',
      );
    }
    if (trimmed.toLowerCase().contains('<html')) {
      return MachineCommandParseResult(
        stage: MachineCommandStage.invalidJson,
        message: 'HTTP success but HTML body, not JSON. Body: ${_clip(trimmed)}',
      );
    }
    try {
      final decoded = _decodeJsonPossiblyTwice(trimmed);
      if (decoded is! Map) {
        return MachineCommandParseResult(
          stage: MachineCommandStage.invalidJson,
          message: 'HTTP $statusCode JSON was not an object. Body: ${_clip(trimmed)}',
        );
      }
      final map = _stringKeyedMap(decoded);
      if (!map.containsKey('success')) {
        return MachineCommandParseResult(
          stage: MachineCommandStage.rejected,
          message:
              'Machine did not include success=true. Present keys: ${map.keys.join(', ')}. Body: ${_clip(trimmed)}',
          payload: map,
        );
      }
      final success = _asBool(map['success']);
      if (success == true) {
        return MachineCommandParseResult(
          stage: MachineCommandStage.accepted,
          message: map['message']?.toString() ?? 'Command accepted',
          success: true,
          payload: map,
        );
      }
      return MachineCommandParseResult(
        stage: MachineCommandStage.rejected,
        message:
            'Machine rejected command (success=${map['success']}). ${map['message'] ?? map['error'] ?? ''} Body: ${_clip(trimmed)}',
        success: false,
        payload: map,
      );
    } catch (_) {
      return MachineCommandParseResult(
        stage: MachineCommandStage.invalidJson,
        message: 'HTTP $statusCode body was not valid JSON. Body: ${_clip(trimmed)}',
      );
    }
  }

  bool isCommandSuccess(int statusCode, String body) {
    return parseCommand(statusCode, body).accepted;
  }

  MachineInfo? parseInfo(String body) {
    final trimmed = _stripBom(body).trim();
    if (trimmed.isEmpty) return null;
    try {
      final decoded = _decodeJsonPossiblyTwice(trimmed);
      if (decoded is! Map) return null;
      final map = _stringKeyedMap(decoded);
      final motor = map['motor'] is Map ? _stringKeyedMap(map['motor'] as Map) : const <String, dynamic>{};
      final mechanical =
          map['mechanical'] is Map ? _stringKeyedMap(map['mechanical'] as Map) : const <String, dynamic>{};
      final calibration =
          map['calibration'] is Map ? _stringKeyedMap(map['calibration'] as Map) : const <String, dynamic>{};
      final sensors = map['sensors'] is Map ? _stringKeyedMap(map['sensors'] as Map) : const <String, dynamic>{};

      final confirmed = _asBool(calibration['confirmed']) ?? false;
      final microsteps = _asInt(calibration['microsteps']);
      final positive = calibration.containsKey('positiveDirectionIsCW')
          ? _asBool(calibration['positiveDirectionIsCW'])
          : null;
      final pulsesPerRevolution =
          _asNum(calibration['pulsesPerRevolution']) ?? _asNum(calibration['stepsPerRevolution']);
      final pulsesPerDegree =
          _asNum(calibration['pulsesPerDegree']) ?? _asNum(calibration['stepsPerDegree']);

      return MachineInfo(
        machineId: map['machineId']?.toString(),
        firmware: map['firmware']?.toString(),
        motorStepAngle: _asNum(motor['stepAngle']),
        gearRatio: _asNum(mechanical['gearRatio']),
        microsteps: microsteps,
        stepsPerRevolution: confirmed ? pulsesPerRevolution : null,
        stepsPerDegree: confirmed ? pulsesPerDegree : null,
        pulsesPerRevolution: pulsesPerRevolution,
        pulsesPerDegree: pulsesPerDegree,
        positiveDirectionIsCW: positive,
        calibrationConfirmed: confirmed && microsteps != null && microsteps > 0 && positive != null,
        hasHomeSensor: _asBool(sensors['home']) ?? false,
        hasLimitSensor: _asBool(sensors['limit']) ?? false,
        raw: map,
      );
    } catch (_) {
      return null;
    }
  }

  bool parseHealthOk(int statusCode, String body) {
    if (statusCode != 200) return false;
    final trimmed = _stripBom(body).trim();
    if (trimmed.isEmpty) return false;
    try {
      final decoded = _decodeJsonPossiblyTwice(trimmed);
      if (decoded is! Map) return false;
      final map = _stringKeyedMap(decoded);
      if (map.containsKey('ok') && _asBool(map['ok']) == false) return false;
      if (map.containsKey('healthy') && _asBool(map['healthy']) == false) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _extractStatusObject(Map<String, dynamic> root) {
    final canonicalRoot = _canonicalize(root);
    if (_containsAllRequiredKeys(canonicalRoot)) {
      return canonicalRoot;
    }
    for (final value in root.values) {
      if (value is Map) {
        final nested = _canonicalize(_stringKeyedMap(value));
        if (_containsAllRequiredKeys(nested)) {
          return nested;
        }
      } else if (value is String) {
        try {
          final inner = _decodeJsonPossiblyTwice(value);
          if (inner is Map) {
            final nested = _canonicalize(_stringKeyedMap(inner));
            if (_containsAllRequiredKeys(nested)) {
              return nested;
            }
          }
        } catch (_) {}
      }
    }
    return canonicalRoot;
  }

  Map<String, dynamic> _canonicalize(Map<String, dynamic> input) {
    final out = <String, dynamic>{};
    input.forEach((key, value) {
      final trimmedKey = key.trim();
      out[trimmedKey] = value;
      final alias = DiamondCamProtocol.statusKeyAliases[trimmedKey];
      if (alias != null && !out.containsKey(alias)) {
        out[alias] = value;
      }
    });
    return out;
  }

  dynamic _decodeJsonPossiblyTwice(String source) {
    final first = jsonDecode(source);
    if (first is String) {
      _log('JSON was a string; decoding second time');
      return jsonDecode(first);
    }
    return first;
  }

  Map<String, dynamic> _stringKeyedMap(Map decoded) {
    return Map<String, dynamic>.from(
      decoded.map((key, value) => MapEntry(key.toString().trim(), value)),
    );
  }

  bool _containsAllRequiredKeys(Map obj) {
    for (final key in requiredKeys) {
      if (!obj.containsKey(key)) {
        return false;
      }
    }
    return true;
  }

  bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) {
      if (value == 1) return true;
      if (value == 0) return false;
    }
    if (value is String) {
      final lower = value.trim().toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return null;
  }

  num? _asNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value.trim());
    return null;
  }

  int? _asInt(dynamic value) {
    final n = _asNum(value);
    if (n == null) return null;
    return n.round();
  }

  String _stripBom(String value) {
    if (value.isNotEmpty && value.codeUnitAt(0) == 0xFEFF) {
      return value.substring(1);
    }
    return value;
  }

  String _clip(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ');
    if (compact.length <= 400) return compact;
    return '${compact.substring(0, 400)}…';
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[DiamondCam Status Parser] $message');
    }
  }
}
