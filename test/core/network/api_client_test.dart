import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/core/network/api_client.dart';

import '../../helpers/fake_http.dart';

const _baseUrl = 'https://api.example.test';

/// An [ApiClient] whose "network" answers every request with [respond].
ApiClient _clientThat(ResponseBody Function(RequestOptions request) respond) {
  return ApiClient(
    baseUrl: _baseUrl,
    httpClientAdapter: FakeHttpAdapter(respond),
  );
}

void main() {
  group('successful requests', () {
    test(
      'sends a GET to the base URL + path, with the query parameters',
      () async {
        final adapter = FakeHttpAdapter((_) => jsonResponse('{}'));
        final client = ApiClient(baseUrl: _baseUrl, httpClientAdapter: adapter);

        await client.getJson(
          '/products',
          queryParameters: {'limit': 2, 'skip': 0},
        );

        final request = adapter.lastRequest!;
        expect(request.method, 'GET');
        expect(
          request.uri.toString(),
          'https://api.example.test/products?limit=2&skip=0',
        );
      },
    );

    test('returns the decoded JSON body', () async {
      final client = _clientThat(
        (_) => jsonResponse(readFixture('products_page.json')),
      );

      final json = await client.getJson('/products');

      expect(json['total'], 194);
      expect(json['products'], hasLength(2));
    });

    test('gives up on slow connections and slow responses', () async {
      final adapter = FakeHttpAdapter((_) => jsonResponse('{}'));
      final client = ApiClient(baseUrl: _baseUrl, httpClientAdapter: adapter);

      await client.getJson('/products');

      expect(adapter.lastRequest!.connectTimeout, const Duration(seconds: 10));
      expect(adapter.lastRequest!.receiveTimeout, const Duration(seconds: 10));
    });
  });

  group('getJsonList (for endpoints that answer with a JSON array)', () {
    test('returns the decoded list', () async {
      final client = _clientThat(
        (_) => jsonResponse(readFixture('categories.json')),
      );

      final json = await client.getJsonList('/products/categories');

      expect(json, hasLength(3));
    });

    test('an object instead of a list → UnexpectedResponseException', () async {
      final client = _clientThat((_) => jsonResponse('{"oops": true}'));

      await expectLater(
        client.getJsonList('/products/categories'),
        throwsA(isA<UnexpectedResponseException>()),
      );
    });

    test('failures become our own error types too', () async {
      final client = _clientThat(
        (_) => jsonResponse('{"message": "oops"}', statusCode: 500),
      );

      await expectLater(
        client.getJsonList('/products/categories'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('failures become our own error types', () {
    test('404 → NotFoundException', () async {
      final client = _clientThat(
        (_) => jsonResponse(
          '{"message": "Product with id \'99999\' not found"}',
          statusCode: 404,
        ),
      );

      await expectLater(
        client.getJson('/products/99999'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('500 → ServerException with the status code', () async {
      final client = _clientThat(
        (_) => jsonResponse('{"message": "oops"}', statusCode: 500),
      );

      await expectLater(
        client.getJson('/products'),
        throwsA(
          isA<ServerException>().having(
            (error) => error.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
    });

    test('connection timeout → RequestTimeoutException', () async {
      final client = _clientThat(
        (request) => throw DioException.connectionTimeout(
          timeout: const Duration(seconds: 10),
          requestOptions: request,
        ),
      );

      await expectLater(
        client.getJson('/products'),
        throwsA(isA<RequestTimeoutException>()),
      );
    });

    test('receive timeout → RequestTimeoutException', () async {
      final client = _clientThat(
        (request) => throw DioException.receiveTimeout(
          timeout: const Duration(seconds: 10),
          requestOptions: request,
        ),
      );

      await expectLater(
        client.getJson('/products'),
        throwsA(isA<RequestTimeoutException>()),
      );
    });

    test('lost connection → NetworkException', () async {
      // This is how dio reports "no internet" on a phone.
      final client = _clientThat(
        (request) => throw DioException.connectionError(
          requestOptions: request,
          reason: 'Failed host lookup',
          error: const SocketException('Failed host lookup'),
        ),
      );

      await expectLater(
        client.getJson('/products'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('a raw socket failure → NetworkException', () async {
      final client = _clientThat(
        (_) => throw const SocketException('Connection reset'),
      );

      await expectLater(
        client.getJson('/products'),
        throwsA(isA<NetworkException>()),
      );
    });

    test(
      'a body that is not a JSON object → UnexpectedResponseException',
      () async {
        final client = _clientThat((_) => jsonResponse('[1, 2, 3]'));

        await expectLater(
          client.getJson('/products'),
          throwsA(isA<UnexpectedResponseException>()),
        );
      },
    );

    test(
      'a body that is not valid JSON → UnexpectedResponseException',
      () async {
        final client = _clientThat((_) => jsonResponse('<html>Oops</html>'));

        await expectLater(
          client.getJson('/products'),
          throwsA(isA<UnexpectedResponseException>()),
        );
      },
    );
  });

  test('every error type has a message for the user', () {
    const errors = <AppException>[
      NetworkException(),
      RequestTimeoutException(),
      NotFoundException(),
      ServerException(500),
      UnexpectedResponseException(),
      UnknownException(),
    ];

    for (final error in errors) {
      expect(error.message, isNotEmpty, reason: '${error.runtimeType}');
    }
  });
}
