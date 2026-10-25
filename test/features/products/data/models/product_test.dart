import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';

/// One product object exactly as DummyJSON sends it, with [changes] applied.
Map<String, dynamic> _productJson([Map<String, dynamic> changes = const {}]) {
  return {
    'id': 2,
    'title': 'Eyeshadow Palette with Mirror',
    'description': 'A versatile range of eyeshadow shades.',
    'price': 19.99,
    'rating': 2.86,
    'category': 'beauty',
    'thumbnail': 'https://cdn.dummyjson.com/example/thumbnail.webp',
    ...changes,
  };
}

void main() {
  test('reads a product from a real API response', () {
    final page = jsonDecode(
      File('test/fixtures/products_page.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final json = (page['products'] as List<dynamic>).first;

    final product = Product.fromJson(json as Map<String, dynamic>);

    expect(product.id, 1);
    expect(product.title, 'Essence Mascara Lash Princess');
    expect(product.priceCents, 999);
    expect(product.rating, 2.56);
    expect(product.category, 'beauty');
    expect(product.thumbnailUrl, endsWith('thumbnail.webp'));
  });

  test('converts the price to cents with rounding, not truncation', () {
    // 19.99 * 100 is 1998.9999999999998 in floating point: .toInt() would
    // give 1998 and lose a cent.
    expect(Product.fromJson(_productJson()).priceCents, 1999);
  });

  test('accepts whole-number prices and ratings', () {
    final product = Product.fromJson(_productJson({'price': 10, 'rating': 4}));

    expect(product.priceCents, 1000);
    expect(product.rating, 4.0);
  });

  test('ignores fields the app does not use', () {
    final product = Product.fromJson(
      _productJson({
        'brand': 'Glamour Beauty',
        'tags': ['beauty'],
      }),
    );

    expect(product.id, 2);
  });

  test('throws a FormatException when a field is missing', () {
    final json = _productJson()..remove('price');

    expect(() => Product.fromJson(json), throwsFormatException);
  });

  test('throws a FormatException when a field has the wrong type', () {
    expect(
      () => Product.fromJson(_productJson({'price': '19.99'})),
      throwsFormatException,
    );
  });
}
