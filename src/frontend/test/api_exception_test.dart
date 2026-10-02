import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/data/remote/api_exception.dart';

void main() {
  test('classifies connection failures as network failures', () {
    final exception = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/api/pasien/register'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(exception.kind, ApiFailureKind.network);
    expect(exception.isNetworkFailure, isTrue);
  });

  test(
    'classifies HTTP validation responses separately from network failures',
    () {
      final exception = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/api/pasien/register'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/api/pasien/register'),
            statusCode: 400,
            data: <String, dynamic>{'message': 'Validation failed'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(exception.kind, ApiFailureKind.validation);
      expect(exception.isNetworkFailure, isFalse);
      expect(exception.message, 'Validation failed');
    },
  );
}
