import 'dart:io';

import 'package:dio/dio.dart';

import '../local/istoria_schema.dart';
import '../local/pasien_schema.dart';

class ApiClient {
  ApiClient({String? baseUrl})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ??
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

  Future<Map<String, dynamic>> registerPasien(Pasien pasien) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/pasien/register',
      data: pasien.toApiJson(),
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> createIstoria(IstoriaKlinis istoria) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/istoria-klinis/create',
      data: istoria.toApiJson(),
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> getIstoriaByPasien(
    String pasienId,
  ) async {
    final response = await dio.get<List<dynamic>>('/istoria-klinis/pasien/$pasienId');
    return (response.data ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();
  }
}
