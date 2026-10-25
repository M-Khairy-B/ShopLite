import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/data/product_catalog.dart';

Product _product(int id, String category) {
  return Product(
    id: id,
    title: 'Product $id',
    description: '',
    priceCents: 100,
    rating: 4,
    category: category,
    thumbnailUrl: '',
  );
}

void main() {
  final products = [
    _product(1, 'groceries'),
    _product(2, 'beauty'),
    _product(3, 'groceries'),
    _product(4, 'furniture'),
  ];

  group('categoriesOf', () {
    test('lists each category once, in the order it first appears', () {
      expect(categoriesOf(products), ['groceries', 'beauty', 'furniture']);
    });

    test('is empty for no products', () {
      expect(categoriesOf([]), isEmpty);
    });
  });

  group('productsInCategory', () {
    test('keeps only the products in that category', () {
      final groceries = productsInCategory(products, 'groceries');

      expect(groceries.map((product) => product.id), [1, 3]);
    });

    test('is empty for a category with no products', () {
      expect(productsInCategory(products, 'laptops'), isEmpty);
    });
  });
}
