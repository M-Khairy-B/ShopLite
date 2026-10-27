import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/core/network/api_client.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/data/models/product_category.dart';
import 'package:e_commerce_learn/features/products/data/models/products_page.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';

/// [ProductsRepository] backed by the DummyJSON API.
class DummyJsonProductsRepository implements ProductsRepository {
  DummyJsonProductsRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Only the fields `Product` reads, so responses stay small: a full
  /// DummyJSON product has over 20 fields (reviews, dimensions, ...).
  static const _fields = 'title,description,price,rating,category,thumbnail';

  @override
  Future<ProductsPage> getProducts({
    required int skip,
    required int limit,
  }) async {
    final json = await _apiClient.getJson(
      '/products',
      queryParameters: {'skip': skip, 'limit': limit, 'select': _fields},
    );
    return _parse(() => ProductsPage.fromJson(json));
  }

  @override
  Future<Product> getProduct(int id) async {
    final json = await _apiClient.getJson(
      '/products/$id',
      queryParameters: {'select': _fields},
    );
    return _parse(() => Product.fromJson(json));
  }

  /// The categories, once they've been loaded. They rarely change, so they
  /// are fetched once per app session and then reused.
  List<ProductCategory>? _categories;

  @override
  Future<List<ProductCategory>> getCategories() async {
    final cached = _categories;
    if (cached != null) {
      return cached;
    }

    final json = await _apiClient.getJsonList('/products/categories');
    final categories = _parse(() => ProductCategory.listFromJson(json));
    // Every caller gets this same list, so nobody may change it. A failure
    // above throws before this line: errors are never remembered.
    return _categories = List.unmodifiable(categories);
  }
}

/// Runs [parse], turning bad data from the server into an app error.
///
/// `fromJson` throws a [FormatException] for data in the wrong shape; callers
/// of the repository only ever see [AppException]s.
T _parse<T>(T Function() parse) {
  try {
    return parse();
  } on FormatException {
    throw const UnexpectedResponseException();
  }
}
