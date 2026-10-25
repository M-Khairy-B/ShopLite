import 'dart:async';

import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/features/products/data/mock_products.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/data/models/products_page.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';

/// A [ProductsRepository] for tests: answers from [products] (the mock
/// catalog by default) without any network.
///
/// - Set [error] to make every call fail with it (set it back to `null` to
///   let a retry succeed).
/// - Set [gate] to hold every answer until the test completes it, so the
///   test can look at the loading state.
class FakeProductsRepository implements ProductsRepository {
  FakeProductsRepository({this.products = mockProducts, this.error, this.gate});

  final List<Product> products;
  AppException? error;
  Completer<void>? gate;

  /// How often each method was called, so tests can check (re)loading.
  int getProductsCalls = 0;
  int getProductCalls = 0;

  /// Every page that was asked for, in order.
  final requestedPages = <({int skip, int limit})>[];

  @override
  Future<ProductsPage> getProducts({
    required int skip,
    required int limit,
  }) async {
    getProductsCalls++;
    requestedPages.add((skip: skip, limit: limit));
    await _waitThenMaybeFail();
    return ProductsPage(
      products: products.skip(skip).take(limit).toList(),
      total: products.length,
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

  Future<void> _waitThenMaybeFail() async {
    await gate?.future;
    final error = this.error;
    if (error != null) {
      throw error;
    }
  }
}
