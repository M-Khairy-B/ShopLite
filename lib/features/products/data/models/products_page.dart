import 'package:e_commerce_learn/features/products/data/models/product.dart';

/// One page of products, as returned by DummyJSON's `/products` endpoints.
///
/// The API returns products in pages: [skip] says how many came before this
/// page, [limit] how many were asked for, and [total] how many exist in all.
class ProductsPage {
  const ProductsPage({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  /// Reads a page from the API's JSON. Throws a [FormatException] if the
  /// shape is wrong.
  factory ProductsPage.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'products': final List<dynamic> products,
        'total': final int total,
        'skip': final int skip,
        'limit': final int limit,
      } =>
        ProductsPage(
          products: [for (final item in products) _productFrom(item)],
          total: total,
          skip: skip,
          limit: limit,
        ),
      _ => throw FormatException('Not a valid products page: $json'),
    };
  }

  final List<Product> products;
  final int total;
  final int skip;
  final int limit;
}

/// Reads one item of the `products` list, which must be a JSON object.
Product _productFrom(Object? item) {
  return switch (item) {
    final Map<String, dynamic> json => Product.fromJson(json),
    _ => throw FormatException('Not a product object: $item'),
  };
}
