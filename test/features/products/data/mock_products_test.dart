import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/products/data/mock_products.dart';

void main() {
  test('mockCategories lists each category once, in catalog order', () {
    expect(mockCategories, ['beauty', 'fragrances', 'laptops', 'smartphones']);
  });

  group('findMockProductsByCategory', () {
    test('returns only the products in that category', () {
      final laptops = findMockProductsByCategory('laptops');

      expect(laptops.map((product) => product.id), [78, 79]);
    });

    test('returns an empty list for an unknown category', () {
      expect(findMockProductsByCategory('furniture'), isEmpty);
    });
  });
}
