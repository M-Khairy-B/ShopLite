import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/products/data/models/product_category.dart';

import '../../../../helpers/fake_http.dart';

void main() {
  test('reads the real list of categories', () {
    final json = jsonDecode(readFixture('categories.json')) as List<dynamic>;

    final categories = ProductCategory.listFromJson(json);

    expect(categories, const [
      ProductCategory(slug: 'beauty', name: 'Beauty'),
      ProductCategory(slug: 'home-decoration', name: 'Home Decoration'),
      ProductCategory(slug: 'laptops', name: 'Laptops'),
    ]);
  });

  test('a category without a name is rejected', () {
    expect(
      () => ProductCategory.fromJson({'slug': 'beauty'}),
      throwsFormatException,
    );
  });

  test('a list item that is not an object is rejected', () {
    expect(
      () => ProductCategory.listFromJson(['beauty']),
      throwsFormatException,
    );
  });
}
