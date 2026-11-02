import 'package:json_annotation/json_annotation.dart';
import 'package:e_commerce_learn/core/utils/read_json.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';

part 'products_page.g.dart';

/// One page of products, as returned by DummyJSON's `/products` endpoints.
///
/// The API returns products in pages: [skip] says how many came before this
/// page, [limit] how many were asked for, and [total] how many exist in all.
@JsonSerializable()
class ProductsPage {
  const ProductsPage({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  /// Reads a page from the API's JSON. Throws a [FormatException] if the
  /// shape is wrong.
  ///
  /// Each item of `products` is read with [Product.fromJson]: the generator
  /// finds that factory by itself.
  factory ProductsPage.fromJson(Map<String, dynamic> json) =>
      readJson(() => _$ProductsPageFromJson(json));

  final List<Product> products;
  final int total;
  final int skip;
  final int limit;

  /// Whether the server has products after this page.
  ///
  /// Counted from the server's own numbers ([skip], [total]), so it stays
  /// right even if the app leaves out a duplicate. An empty page means
  /// "nothing more", whatever [total] says: otherwise a server that miscounts
  /// would make the app ask for more forever.
  bool get hasMore => products.isNotEmpty && skip + products.length < total;
}
