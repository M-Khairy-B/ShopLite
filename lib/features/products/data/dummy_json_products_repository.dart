import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/core/network/api_client.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/data/models/product_category.dart';
import 'package:e_commerce_learn/features/products/data/models/products_page.dart';
import 'package:e_commerce_learn/features/products/data/product_sort.dart';
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
    String? category,
    ProductSort sort = ProductSort.featured,
  }) async {
    // DummyJSON has a separate endpoint per category. The slug comes from a
    // URL the user could type, so it is encoded: a slug like "../carts"
    // must not reach another endpoint.
    final path = category == null
        ? '/products'
        : '/products/category/${Uri.encodeComponent(category)}';
    final json = await _apiClient.getJson(
      path,
      queryParameters: {
        'skip': skip,
        'limit': limit,
        'select': _fields,
        ..._sortParameters(sort),
      },
    );
    return _parse(() => ProductsPage.fromJson(json));
  }

  /// How DummyJSON is asked for each order. The server sorts the whole
  /// catalog, so page 2 continues where page 1 stopped.
  static Map<String, Object?> _sortParameters(ProductSort sort) {
    return switch (sort) {
      ProductSort.featured => const {}, // the API's own order
      ProductSort.priceLowToHigh => const {'sortBy': 'price', 'order': 'asc'},
      ProductSort.priceHighToLow => const {'sortBy': 'price', 'order': 'desc'},
      ProductSort.topRated => const {'sortBy': 'rating', 'order': 'desc'},
    };
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
