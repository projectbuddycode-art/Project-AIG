import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:aig/features/esp32/services/machine_endpoint_config.dart';
import 'package:aig/features/esp32/services/machine_status_parser.dart';

class MachineHttpResponse {
  const MachineHttpResponse({
    required this.requestId,
    required this.method,
    required this.uri,
    required this.statusCode,
    required this.body,
    required this.elapsedMs,
    required this.accepted,
  });

  final String requestId;
  final String method;
  final Uri uri;
  final int statusCode;
  final String body;
  final int elapsedMs;
  final bool accepted;
}

class MachineHttpClient {
  MachineHttpClient({
    HttpClient? client,
    MachineStatusParser? parser,
    Duration timeout = const Duration(seconds: 5),
  })  : _client = client ?? HttpClient()
          ..connectionTimeout = timeout
          ..idleTimeout = timeout,
        _parser = parser ?? MachineStatusParser(),
        _timeout = timeout;

  final HttpClient _client;
  final MachineStatusParser _parser;
  final Duration _timeout;
  int _requestSeq = 0;

  MachineStatusParser get parser => _parser;

  Future<MachineHttpResponse> get(String path) {
    return send('GET', path, body: const {});
  }

  Future<MachineHttpResponse> post(String path, Map<String, Object?> body) {
    return send('POST', path, body: body);
  }

  Future<MachineHttpResponse> send(
    String method,
    String path, {
    Map<String, Object?> body = const {},
  }) async {
    final requestId = 'm${DateTime.now().millisecondsSinceEpoch}-${_requestSeq++}';
    final config = MachineEndpointConfig.current;
    final uri = config.uriFor(path);
    final started = DateTime.now();
    final bool isGet = method == 'GET';
    // Encode once. A second jsonEncode would wrap the object in quotes and
    // the ESP32 would reject it. Content-Length is required: without it Dart
    // uses chunked transfer, and ESP32 WebServer leaves arg("plain") empty.
    final String? encodedBody = isGet ? null : jsonEncode(body);
    final List<int> bytes = encodedBody == null ? const <int>[] : utf8.encode(encodedBody);
    _log(
      'METHOD=$method URL=${config.describe(uri)} '
      'CONTENT-TYPE=${isGet ? '-' : 'application/json'} '
      'BODY=${encodedBody ?? '-'} requestId=$requestId',
    );
    try {
      final HttpClientRequest request = isGet
          ? await _client.getUrl(uri).timeout(_timeout)
          : await _client.postUrl(uri).timeout(_timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.connectionHeader, 'close');
      if (!isGet) {
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        request.contentLength = bytes.length;
        if (bytes.isNotEmpty) {
          request.add(bytes);
        }
      }
      final response = await request.close().timeout(_timeout);
      final responseBody = await response.transform(utf8.decoder).join().timeout(_timeout);
      final elapsed = DateTime.now().difference(started).inMilliseconds;
      final accepted = method == 'GET'
          ? response.statusCode == HttpStatus.ok
          : _parser.isCommandSuccess(response.statusCode, responseBody);
      _log(
        'HTTP STATUS=${response.statusCode} ELAPSED=${elapsed}ms RAW RESPONSE BODY=$responseBody',
      );
      return MachineHttpResponse(
        requestId: requestId,
        method: method,
        uri: uri,
        statusCode: response.statusCode,
        body: responseBody,
        elapsedMs: elapsed,
        accepted: accepted,
      );
    } catch (error) {
      final elapsed = DateTime.now().difference(started).inMilliseconds;
      _log('TRANSPORT ERROR requestId=$requestId error=$error elapsedMs=$elapsed');
      rethrow;
    }
  }

  void _log(String message) {
    if (kDebugMode || machineHttpDebugEnabled()) {
      debugPrint('[AIG_MACHINE] $message');
    }
  }
}

int backoffMs(int attempt) => 250 * pow(2, attempt - 1).toInt();
