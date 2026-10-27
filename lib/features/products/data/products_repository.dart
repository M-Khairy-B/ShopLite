import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/data/models/product_category.dart';
import 'package:e_commerce_learn/features/products/data/models/products_page.dart';

/// Where products come from, as far as the rest of the app is concerned.
///
/// Screens (and later, Cubits) depend on this interface only. They don't
/// know whether products come from DummyJSON, from Supabase (Phase 9), or
/// from a fake in a test.
///
/// Both methods throw an `AppException` when something goes wrong.
abstract interface class ProductsRepository {
  /// One page of the catalog: [limit] products, after skipping [skip].
  /// With a [category] (its slug), only that category's products.
  Future<ProductsPage> getProducts({
    required int skip,
    required int limit,
    String? category,
  });

  /// The product with this [id]. Throws a `NotFoundException` if it doesn't
  /// exist.
  Future<Product> getProduct(int id);

  /// Every product category. Categories rarely change, so implementations
  /// may remember them after the first successful call.
  Future<List<ProductCategory>> getCategories();
}
