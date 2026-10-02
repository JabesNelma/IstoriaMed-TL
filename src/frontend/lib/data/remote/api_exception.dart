import 'package:dio/dio.dart';

enum ApiFailureKind { network, validation, server, unknown }

class ApiException implements Exception {
  const ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
  });

  final ApiFailureKind kind;
  final String message;
  final int? statusCode;

  bool get isNetworkFailure => kind == ApiFailureKind.network;

  factory ApiException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final kind = switch (error.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => ApiFailureKind.network,
      _ when statusCode != null && statusCode >= 400 && statusCode < 500 =>
        ApiFailureKind.validation,
      _ when statusCode != null && statusCode >= 500 => ApiFailureKind.server,
      _ => ApiFailureKind.unknown,
    };

    final responseMessage = error.response?.data is Map
        ? (error.response!.data as Map)['message']
        : null;
    return ApiException(
      kind: kind,
      statusCode: statusCode,
      message: responseMessage is String
          ? responseMessage
          : error.message ?? 'Request API la konsege.',
    );
  }

  @override
  String toString() => 'ApiException($kind, $statusCode): $message';
}
