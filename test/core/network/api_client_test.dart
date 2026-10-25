import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/network/api_client.dart';

const _baseUrl = 'https://api.example.test';

/// Stands in for the network: remembers the last request and answers it
/// with the response built by [respond]. No real connection is made.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final ResponseBody Function() respond;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return respond();
  }

  @override
  void close({bool force = false}) {}
}

/// A JSON response with [body] and [statusCode], like a real server sends.
ResponseBody _jsonResponse(String body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    body,
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  test(
    'sends a GET to the base URL + path, with the query parameters',
    () async {
      final adapter = _FakeAdapter(() => _jsonResponse('{}'));
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
    final fixture = File('test/fixtures/products_page.json').readAsStringSync();
    final client = ApiClient(
      baseUrl: _baseUrl,
      httpClientAdapter: _FakeAdapter(() => _jsonResponse(fixture)),
    );

    final json = await client.getJson('/products');

    expect(json['total'], 194);
    expect(json['products'], hasLength(2));
  });

  test('gives up on slow connections and slow responses', () async {
    final adapter = _FakeAdapter(() => _jsonResponse('{}'));
    final client = ApiClient(baseUrl: _baseUrl, httpClientAdapter: adapter);

    await client.getJson('/products');

    expect(adapter.lastRequest!.connectTimeout, const Duration(seconds: 10));
    expect(adapter.lastRequest!.receiveTimeout, const Duration(seconds: 10));
  });

  test('an error status such as 404 fails with an exception', () async {
    final client = ApiClient(
      baseUrl: _baseUrl,
      httpClientAdapter: _FakeAdapter(
        () => _jsonResponse(
          '{"message": "Product with id \'99999\' not found"}',
          statusCode: 404,
        ),
      ),
    );

    // Task 3 replaces dio's exception with our own error types.
    await expectLater(
      client.getJson('/products/99999'),
      throwsA(isA<DioException>()),
    );
  });

  test(
    'a body that is not a JSON object fails with a FormatException',
    () async {
      final client = ApiClient(
        baseUrl: _baseUrl,
        httpClientAdapter: _FakeAdapter(() => _jsonResponse('[1, 2, 3]')),
      );

      await expectLater(client.getJson('/products'), throwsFormatException);
    },
  );
}
