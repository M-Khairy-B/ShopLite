import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';

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
  /// Every failure is thrown as an [AppException]: network problems, error
  /// status codes (4xx, 5xx), and bodies that aren't a JSON object.
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? queryParameters,
  }) async {
    return switch (await _get(path, queryParameters)) {
      final Map<String, dynamic> json => json,
      _ => throw const UnexpectedResponseException(),
    };
  }

  /// Like [getJson], for endpoints that answer with a JSON array instead of
  /// an object, such as `/products/categories`.
  Future<List<dynamic>> getJsonList(
    String path, {
    Map<String, Object?>? queryParameters,
  }) async {
    return switch (await _get(path, queryParameters)) {
      final List<dynamic> json => json,
      _ => throw const UnexpectedResponseException(),
    };
  }

  /// Sends the GET request and returns the decoded body, whatever its shape.
  /// The public methods check the shape they expect.
  Future<Object?> _get(
    String path,
    Map<String, Object?>? queryParameters,
  ) async {
    try {
      final response = await _dio.get<Object?>(
        path,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (error) {
      throw _toAppException(error);
    }
  }
}

/// Translates one of dio's errors into the app's own [AppException].
///
/// This is the only place in the app that knows about dio's error types.
AppException _toAppException(DioException error) {
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => const RequestTimeoutException(),
    DioExceptionType.connectionError ||
    DioExceptionType.badCertificate => const NetworkException(),
    DioExceptionType.badResponse => switch (error.response?.statusCode) {
      404 => const NotFoundException(),
      final statusCode => ServerException(statusCode),
    },
    DioExceptionType.cancel => const UnknownException(),
    // "unknown" wraps errors dio didn't classify: look at the original one.
    DioExceptionType.unknown => switch (error.error) {
      SocketException() => const NetworkException(),
      FormatException() => const UnexpectedResponseException(),
      _ => const UnknownException(),
    },
  };
}
