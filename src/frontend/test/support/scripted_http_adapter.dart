import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Scriptable [HttpClientAdapter] so sync behaviour can be exercised without a
/// physical network toggle while still going through the real Dio pipeline and
/// the real [ApiException] classification.
class ScriptedHttpAdapter implements HttpClientAdapter {
  ScriptedHttpAdapter(this.responder);

  final Future<ResponseBody> Function(RequestOptions options) responder;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return responder(options);
  }

  @override
  void close({bool force = false}) {}

  List<Map<String, dynamic>> get sentOperations => requests
      .where((request) => request.path.endsWith('/sync/operations'))
      .map((request) {
        final body = request.data;
        final decoded = body is String ? jsonDecode(body) as Map<String, dynamic> : Map<String, dynamic>.from(body as Map);
        return Map<String, dynamic>.from(decoded['operation'] as Map);
      })
      .toList();

  List<String> get sentOperationIds =>
      sentOperations.map((operation) => operation['operation_id'] as String).toList();
}

ResponseBody jsonResponse(int statusCode, Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

/// Response body for endpoints that answer with a JSON array.
ResponseBody jsonListResponse(int statusCode, List<dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

ResponseBody emptyResponse(int statusCode) {
  return ResponseBody.fromString(
    '',
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

DioException networkFailure() => DioException(
      requestOptions: RequestOptions(path: '/api/sync/operations'),
      type: DioExceptionType.connectionError,
      error: const SocketException('Network is unreachable'),
    );

DioException timeoutFailure() => DioException(
      requestOptions: RequestOptions(path: '/api/sync/operations'),
      type: DioExceptionType.connectionTimeout,
    );

DioException httpFailure(int statusCode, {String message = 'rejected'}) => DioException(
      requestOptions: RequestOptions(path: '/api/sync/operations'),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/sync/operations'),
        statusCode: statusCode,
        data: <String, dynamic>{'message': message},
      ),
      type: DioExceptionType.badResponse,
    );
