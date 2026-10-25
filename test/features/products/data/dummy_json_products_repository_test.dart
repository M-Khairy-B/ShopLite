import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/core/network/api_client.dart';
import 'package:e_commerce_learn/features/products/data/dummy_json_products_repository.dart';

import '../../../helpers/fake_http.dart';

/// A repository on top of a fake network that answers with [respond].
({DummyJsonProductsRepository repository, FakeHttpAdapter network})
_repositoryThat(ResponseBody Function(RequestOptions request) respond) {
  final network = FakeHttpAdapter(respond);
  final apiClient = ApiClient(
    baseUrl: 'https://api.example.test',
    httpClientAdapter: network,
  );
  return (repository: DummyJsonProductsRepository(apiClient), network: network);
}

void main() {
  group('getProducts', () {
    test('asks for one page, with only the fields the app uses', () async {
      final (:repository, :network) = _repositoryThat(
        (_) => jsonResponse(readFixture('products_page.json')),
      );

      await repository.getProducts(skip: 30, limit: 15);

      final request = network.lastRequest!;
      expect(request.path, '/products');
      expect(request.queryParameters, {
        'skip': 30,
        'limit': 15,
        'select': 'title,description,price,rating,category,thumbnail',
      });
    });

    test('returns the page as models', () async {
      final (:repository, network: _) = _repositoryThat(
        (_) => jsonResponse(readFixture('products_page.json')),
      );

      final page = await repository.getProducts(skip: 0, limit: 2);

      expect(page.products.map((product) => product.id), [1, 2]);
      expect(page.products.first.priceCents, 999);
      expect(page.total, 194);
    });
  });

  group('getProduct', () {
    test('asks for that product, with only the fields the app uses', () async {
      final (:repository, :network) = _repositoryThat(
        (_) => jsonResponse(readFixture('product.json')),
      );

      await repository.getProduct(1);

      final request = network.lastRequest!;
      expect(request.path, '/products/1');
      expect(
        request.queryParameters['select'],
        'title,description,price,rating,category,thumbnail',
      );
    });

    test('returns the product as a model', () async {
      final (:repository, network: _) = _repositoryThat(
        (_) => jsonResponse(readFixture('product.json')),
      );

      final product = await repository.getProduct(1);

      expect(product.title, 'Essence Mascara Lash Princess');
      expect(product.priceCents, 999);
    });
  });

  group('failures are always AppExceptions', () {
    test(
      'product data in the wrong shape → UnexpectedResponseException',
      () async {
        // A JSON object, so ApiClient accepts it, but no price.
        final (:repository, network: _) = _repositoryThat(
          (_) => jsonResponse('{"id": 1, "title": "Broken"}'),
        );

        await expectLater(
          repository.getProduct(1),
          throwsA(isA<UnexpectedResponseException>()),
        );
      },
    );

    test('a page in the wrong shape → UnexpectedResponseException', () async {
      final (:repository, network: _) = _repositoryThat(
        (_) => jsonResponse('{"products": "oops"}'),
      );

      await expectLater(
        repository.getProducts(skip: 0, limit: 30),
        throwsA(isA<UnexpectedResponseException>()),
      );
    });

    test('errors from ApiClient pass through unchanged', () async {
      final (:repository, network: _) = _repositoryThat(
        (_) => jsonResponse('{"message": "not found"}', statusCode: 404),
      );

      await expectLater(
        repository.getProduct(99999),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
