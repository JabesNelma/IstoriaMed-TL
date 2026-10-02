import 'dart:io';

import 'package:dio/dio.dart';

import '../local/istoria_schema.dart';
import '../local/pasien_schema.dart';
import '../local/prescription_schema.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({String? baseUrl})
    : dio = Dio(
        BaseOptions(
          baseUrl:
              baseUrl ??
              (Platform.isAndroid
                  ? 'http://10.0.2.2:3000/api'
                  : 'http://localhost:3000/api'),
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );

  final Dio dio;

  void setAccessToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAccessToken() {
    dio.options.headers.remove('Authorization');
  }

  Future<Map<String, dynamic>> login({
    required String loginIdentifier,
    required String password,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'login_identifier': loginIdentifier, 'password': password},
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> registerPasien(Pasien pasien) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/pasien/register',
        data: pasien.toApiJson(),
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<Map<String, dynamic>>> searchPasien([String? query]) async {
    try {
      final response = await dio.get<List<dynamic>>(
        '/pasien',
        queryParameters: query == null || query.trim().isEmpty
            ? null
            : {'q': query.trim()},
      );
      return (response.data ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> getPasien(String patientId) async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/pasien/$patientId',
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> updatePasien(
    String patientId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.patch<Map<String, dynamic>>(
        '/pasien/$patientId',
        data: data,
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> createIstoria(IstoriaKlinis istoria) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/istoria-klinis/create',
        data: istoria.toApiJson(),
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<Map<String, dynamic>>> getIstoriaByPasien(String pasienId) async {
    try {
      final response = await dio.get<List<dynamic>>(
        '/istoria-klinis/pasien/$pasienId',
      );
      return (response.data ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// Reads the medication catalog.
  ///
  /// The catalog is server owned reference data: it is global, never tenant or
  /// facility scoped, and is never queued for offline synchronization.
  Future<List<Map<String, dynamic>>> getMedications({
    String? query,
    bool includeInactive = false,
  }) async {
    try {
      final response = await dio.get<List<dynamic>>(
        '/medications',
        queryParameters: <String, dynamic>{
          if (query != null && query.isNotEmpty) 'q': query,
          'include_inactive': includeInactive,
        },
      );
      return (response.data ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> getMedication(String medicationId) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/medications/$medicationId');
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<Map<String, dynamic>>> getPrescriptionsByVisit(String visitId) async {
    try {
      final response = await dio.get<List<dynamic>>('/prescriptions/visit/$visitId');
      return (response.data ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<Map<String, dynamic>> getPrescription(String prescriptionId) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/prescriptions/$prescriptionId');
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// Online prescription create, used when the device has connectivity.
  Future<Map<String, dynamic>> createPrescription(Prescription prescription) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/prescriptions',
        data: prescription.toApiJson(),
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// Submits one queued offline operation.
  ///
  /// `operationId` is the stable idempotency key: retrying the same operation
  /// reuses it, so the server never creates a duplicate medical record.
  Future<Map<String, dynamic>> submitSyncOperation({
    required String operationId,
    required String entityType,
    required String entityId,
    required String operationType,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/sync/operations',
        data: {
          'operation': {
            'operation_id': operationId,
            'entity_type': entityType,
            'entity_id': entityId,
            'operation_type': operationType,
            'payload': payload,
          },
        },
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
