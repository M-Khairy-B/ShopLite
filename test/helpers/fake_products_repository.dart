import 'dart:async';

import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/core/utils/text_format.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/data/models/product_category.dart';
import 'package:e_commerce_learn/features/products/data/models/products_page.dart';
import 'package:e_commerce_learn/features/products/data/product_catalog.dart';
import 'package:e_commerce_learn/features/products/data/product_sort.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';

import 'mock_products.dart';

/// A [ProductsRepository] for tests: answers from [products] (the mock
/// catalog by default) without any network.
///
/// - Set [error] to make every call fail with it (set it back to `null` to
///   let a retry succeed). Usually an [AppException]; anything else plays a
///   repository with a bug, since real repositories throw AppExceptions only.
/// - Set [gate] to hold every answer until the test completes it, so the
///   test can look at the loading state.
class FakeProductsRepository implements ProductsRepository {
  FakeProductsRepository({
    this.products = mockProducts,
    this.categories,
    this.error,
    this.gate,
  });

  /// The catalog. Tests can replace it, e.g. to see a refresh pick up
  /// changes.
  List<Product> products;

  /// The categories to answer with, or `null` to use the categories of
  /// [products].
  final List<ProductCategory>? categories;
  Object? error;
  Completer<void>? gate;

  /// How often each method was called, so tests can check (re)loading.
  int getProductsCalls = 0;
  int getProductCalls = 0;
  int getCategoriesCalls = 0;

  /// Every page that was asked for, in order.
  final requestedPages =
      <({int skip, int limit, String? category, ProductSort sort})>[];

  /// Like the real API: filters by [category], sorts the whole result by
  /// [sort], then cuts out the requested page.
  @override
  Future<ProductsPage> getProducts({
    required int skip,
    required int limit,
    String? category,
    ProductSort sort = ProductSort.featured,
  }) async {
    getProductsCalls++;
    requestedPages.add((
      skip: skip,
      limit: limit,
      category: category,
      sort: sort,
    ));
    await _waitThenMaybeFail();
    final matching = sortProducts(
      category == null ? products : productsInCategory(products, category),
      sort,
    );
    return ProductsPage(
      products: matching.skip(skip).take(limit).toList(),
      total: matching.length,
      skip: skip,
      limit: limit,
    );
  }

  @override
  Future<Product> getProduct(int id) async {
    getProductCalls++;
    await _waitThenMaybeFail();
    for (final product in products) {
      if (product.id == id) {
        return product;
      }
    }
    throw const NotFoundException();
  }

  /// [categories] if given; otherwise the categories of [products], named
  /// like the real API names them (`beauty` → `Beauty`).
  @override
  Future<List<ProductCategory>> getCategories() async {
    getCategoriesCalls++;
    await _waitThenMaybeFail();
    return categories ??
        [
          for (final slug in categoriesOf(products))
            ProductCategory(slug: slug, name: capitalize(slug)),
        ];
  }

  Future<void> _waitThenMaybeFail() async {
    await gate?.future;
    final error = this.error;
    if (error != null) {
      throw error;
    }
  }
}
