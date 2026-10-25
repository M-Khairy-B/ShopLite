import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Stands in for the network: remembers the last request and answers it with
/// whatever [respond] returns, or fails the way [respond] fails. No real
/// connection is made.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.respond);

  final ResponseBody Function(RequestOptions request) respond;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

/// A JSON response with [body] and [statusCode], like a real server sends.
ResponseBody jsonResponse(String body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    body,
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

/// The text of a file in `test/fixtures/` (a real API response).
String readFixture(String name) {
  return File('test/fixtures/$name').readAsStringSync();
}
