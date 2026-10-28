import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/products/data/models/products_page.dart';

import '../../../../helpers/mock_products.dart';

void main() {
  test('reads a page of products from a real API response', () {
    final json = jsonDecode(
      File('test/fixtures/products_page.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    final page = ProductsPage.fromJson(json);

    expect(page.products.map((product) => product.id), [1, 2]);
    expect(page.total, 194);
    expect(page.skip, 0);
    expect(page.limit, 2);
  });

  group('hasMore', () {
    ProductsPage page({required int skip, required int count, int total = 45}) {
      return ProductsPage(
        products: generatedProducts(count),
        total: total,
        skip: skip,
        limit: 30,
      );
    }

    test('is true when products exist after this page', () {
      expect(page(skip: 0, count: 30).hasMore, isTrue);
    });

    test('is false for the last page', () {
      expect(page(skip: 30, count: 15).hasMore, isFalse);
    });

    test('is false for an empty page, whatever the total says', () {
      // Otherwise a server that miscounts would make the app ask forever.
      expect(page(skip: 30, count: 0).hasMore, isFalse);
    });
  });

  test('throws a FormatException when "products" is not a list', () {
    expect(
      () => ProductsPage.fromJson({
        'products': 'oops',
        'total': 0,
        'skip': 0,
        'limit': 0,
      }),
      throwsFormatException,
    );
  });

  test('throws a FormatException when a list item is not an object', () {
    expect(
      () => ProductsPage.fromJson({
        'products': [42],
        'total': 1,
        'skip': 0,
        'limit': 1,
      }),
      throwsFormatException,
    );
  });
}
