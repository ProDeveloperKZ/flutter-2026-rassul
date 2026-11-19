import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_exception.dart';

class ApiClient {
  ApiClient(
    this._client, {
    this.host = 'jsonplaceholder.typicode.com',
    this.timeout = const Duration(seconds: 10),
  });

  final http.Client _client;
  final String host;
  final Duration timeout;

  Map<String, String> get headers => const {'Accept': 'application/json'};

  Future<dynamic> get(Uri uri) async {
    final response = await _send((abortTrigger) async {
      final request = http.AbortableRequest(
        'GET',
        uri,
        abortTrigger: abortTrigger,
      )..headers.addAll(headers);
      return http.Response.fromStream(await _client.send(request));
    });
    _check(response);
    return _decode(response);
  }

  Future<dynamic> post(
    Uri uri, {
    required Object body,
    int expectedStatus = 201,
  }) async {
    final response = await _send((abortTrigger) async {
      final request =
          http.AbortableRequest('POST', uri, abortTrigger: abortTrigger)
            ..headers.addAll({...headers, 'Content-Type': 'application/json'})
            ..body = jsonEncode(body);
      return http.Response.fromStream(await _client.send(request));
    });
    _check(response, expectedStatus: expectedStatus);
    return _decode(response);
  }

  Future<http.Response> _send(
    Future<http.Response> Function(Future<void> abortTrigger) call,
  ) async {
    final abort = Completer<void>();
    final stopwatch = Stopwatch()..start();
    try {
      final response = await call(abort.future).timeout(
        timeout,
        onTimeout: () {
          if (!abort.isCompleted) {
            abort.complete();
          }
          throw TimeoutException('Request timed out', timeout);
        },
      );
      if (kDebugMode) {
        log(
          '${response.request?.method ?? 'HTTP'} '
          '${response.request?.url ?? ''} -> '
          '${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)',
          name: 'api',
        );
      }
      return response;
    } on SocketException {
      if (kDebugMode) {
        log(
          'SocketException after ${stopwatch.elapsedMilliseconds}ms',
          name: 'api',
        );
      }
      throw const NoConnectionException();
    } on TimeoutException {
      if (kDebugMode) {
        log(
          'TimeoutException after ${stopwatch.elapsedMilliseconds}ms',
          name: 'api',
        );
      }
      throw const NoConnectionException();
    } on http.ClientException {
      if (kDebugMode) {
        log(
          'ClientException after ${stopwatch.elapsedMilliseconds}ms',
          name: 'api',
        );
      }
      throw const NoConnectionException();
    }
  }

  void _check(http.Response r, {int? expectedStatus}) {
    if (r.statusCode == 401) {
      throw const UnauthorizedException();
    }
    if (r.statusCode == 404) {
      throw const NotFoundException();
    }
    if (r.statusCode >= 500) {
      throw ServerException(r.statusCode);
    }
    if (expectedStatus != null && r.statusCode != expectedStatus) {
      throw BadResponseException(
        'Expected HTTP $expectedStatus, got ${r.statusCode}',
      );
    }
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw BadResponseException('Unexpected HTTP ${r.statusCode}');
    }
  }

  dynamic _decode(http.Response r) {
    try {
      return jsonDecode(r.body);
    } on FormatException catch (e) {
      throw BadResponseException('Invalid JSON: ${e.message}');
    }
  }

  void close() => _client.close();
}
