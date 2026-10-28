import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/data/product_sort.dart';

// What the real server does with the catalog (filter, sort), done in memory
// so FakeProductsRepository can answer like DummyJSON. The app itself asks
// the server instead, since Phase 5.

/// Every category that appears in [products], each once, in the order it
/// first appears.
List<String> categoriesOf(Iterable<Product> products) {
  return products.map((product) => product.category).toSet().toList();
}

/// The products in [products] that belong to [category] (empty if none).
List<Product> productsInCategory(Iterable<Product> products, String category) {
  return products.where((product) => product.category == category).toList();
}

/// Returns a new list with [products] ordered by [sort]. The original list
/// is never changed (it may be unmodifiable).
List<Product> sortProducts(List<Product> products, ProductSort sort) {
  final sorted = [...products];

  switch (sort) {
    case ProductSort.featured:
      break; // keep the catalog order
    case ProductSort.priceLowToHigh:
      sorted.sort((a, b) => a.priceCents.compareTo(b.priceCents));
    case ProductSort.priceHighToLow:
      sorted.sort((a, b) => b.priceCents.compareTo(a.priceCents));
    case ProductSort.topRated:
      sorted.sort((a, b) => b.rating.compareTo(a.rating));
  }

  return sorted;
}
