import 'package:e_commerce_learn/features/products/data/models/product.dart';

/// Every category that appears in [products], each once, in the order it
/// first appears.
List<String> categoriesOf(Iterable<Product> products) {
  return products.map((product) => product.category).toSet().toList();
}

/// The products in [products] that belong to [category] (empty if none).
List<Product> productsInCategory(Iterable<Product> products, String category) {
  return products.where((product) => product.category == category).toList();
}
