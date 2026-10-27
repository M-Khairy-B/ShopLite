import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/products/data/product_sort.dart';

import '../../../helpers/mock_products.dart';

/// The ids of [sort] applied to the whole mock catalog, in order.
List<int> _sortedIds(ProductSort sort) {
  return sortProducts(mockProducts, sort).map((product) => product.id).toList();
}

void main() {
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
}
