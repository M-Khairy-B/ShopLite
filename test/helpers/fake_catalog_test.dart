import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/data/product_sort.dart';

import 'fake_catalog.dart';
import 'mock_products.dart';

/// The fake server must filter and sort like the real one, or every test
/// built on it checks the wrong thing.
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

  group('sortProducts', () {
    test('featured keeps the catalog order', () {
      expect(_sortedIds(ProductSort.featured), [1, 2, 6, 7, 78, 79, 121, 122]);
    });

    test('price low to high puts the cheapest first', () {
      expect(_sortedIds(ProductSort.priceLowToHigh), [
        1, // $9.99
        2, // $19.99
        6, // $49.99
        7, // $129.99
        121, // $199.99
        122, // $299.99
        79, // $1799.99
        78, // $1999.99
      ]);
    });

    test('price high to low puts the most expensive first', () {
      expect(_sortedIds(ProductSort.priceHighToLow), [
        78,
        79,
        122,
        121,
        7,
        6,
        2,
        1,
      ]);
    });

    test('top rated puts the highest rating first', () {
      expect(_sortedIds(ProductSort.topRated), [
        6, // 4.37
        7, // 4.26
        79, // 3.95
        78, // 3.65
        122, // 3.41
        2, // 2.86
        121, // 2.83
        1, // 2.56
      ]);
    });

    test('returns a new list and leaves the original untouched', () {
      final sorted = sortProducts(mockProducts, ProductSort.priceHighToLow);

      expect(identical(sorted, mockProducts), isFalse);
      expect(mockProducts.first.id, 1);
    });
  });
}

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

/// The ids of [sort] applied to the whole mock catalog, in order.
List<int> _sortedIds(ProductSort sort) {
  return sortProducts(mockProducts, sort).map((product) => product.id).toList();
}
