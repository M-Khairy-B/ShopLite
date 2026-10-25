import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// The one place in the app that talks HTTP.
///
/// Everything above it (repositories, then screens) works with plain Dart
/// values, never with dio directly.
class ApiClient {
  /// [httpClientAdapter] replaces the real network; tests pass a fake one.
  ApiClient({required String baseUrl, HttpClientAdapter? httpClientAdapter})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          // Without timeouts, a request on a bad connection could hang
          // forever and the user would wait for nothing.
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      ) {
    if (httpClientAdapter != null) {
      _dio.httpClientAdapter = httpClientAdapter;
    }
    if (kDebugMode) {
      // Logs each request's method, URL and status in debug builds only.
      // Headers are left out on purpose: from Phase 7 they carry the login
      // token, which must never end up in logs.
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          responseHeader: false,
          logPrint: (message) => debugPrint(message.toString()),
        ),
      );
    }
  }

  final Dio _dio;

  /// Sends a GET request to [path] and returns the JSON object it answers.
  ///
  /// Throws a [DioException] for network problems and error status codes
  /// (4xx, 5xx), and a [FormatException] if the body isn't a JSON object.
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? queryParameters,
  }) async {
    final response = await _dio.get<Object?>(
      path,
      queryParameters: queryParameters,
    );

    return switch (response.data) {
      final Map<String, dynamic> json => json,
      final other => throw FormatException(
        'Expected a JSON object from $path, got: $other',
      ),
    };
  }
}
