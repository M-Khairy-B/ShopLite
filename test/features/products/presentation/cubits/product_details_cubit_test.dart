import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/features/products/data/mock_products.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/data/models/products_page.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';
import 'package:e_commerce_learn/features/products/presentation/cubits/product_details_cubit.dart';
import 'package:e_commerce_learn/features/products/presentation/cubits/product_details_state.dart';

import '../../../../helpers/fake_products_repository.dart';

void main() {
  // Product 1 in the fake catalog.
  final mascara = mockProducts.first;

  test('starts in the loading state', () {
    final cubit = ProductDetailsCubit(
      repository: FakeProductsRepository(),
      productId: 1,
    );

    expect(cubit.state, const ProductDetailsLoading());

    cubit.close();
  });

  blocTest<ProductDetailsCubit, ProductDetailsState>(
    'load emits loading, then the product',
    build: () =>
        ProductDetailsCubit(repository: FakeProductsRepository(), productId: 1),
    act: (cubit) => cubit.load(),
    expect: () => [
      const ProductDetailsLoading(),
      ProductDetailsLoaded(mascara),
    ],
  );

  blocTest<ProductDetailsCubit, ProductDetailsState>(
    'a product that does not exist emits a NotFoundException',
    build: () => ProductDetailsCubit(
      repository: FakeProductsRepository(),
      productId: 999999,
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      const ProductDetailsLoading(),
      const ProductDetailsError(NotFoundException()),
    ],
  );

  blocTest<ProductDetailsCubit, ProductDetailsState>(
    'a failed load emits the error',
    build: () => ProductDetailsCubit(
      repository: FakeProductsRepository(error: const NetworkException()),
      productId: 1,
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      const ProductDetailsLoading(),
      const ProductDetailsError(NetworkException()),
    ],
  );

  late FakeProductsRepository repository;

  blocTest<ProductDetailsCubit, ProductDetailsState>(
    'loading again after an error emits loading, then the product',
    setUp: () {
      repository = FakeProductsRepository(error: const NetworkException());
    },
    build: () => ProductDetailsCubit(repository: repository, productId: 1),
    act: (cubit) async {
      await cubit.load();
      repository.error = null; // the connection is back
      await cubit.load();
    },
    expect: () => [
      const ProductDetailsLoading(),
      const ProductDetailsError(NetworkException()),
      const ProductDetailsLoading(),
      ProductDetailsLoaded(mascara),
    ],
  );

  blocTest<ProductDetailsCubit, ProductDetailsState>(
    'an error that is not an AppException is reported, and shown as unknown',
    build: () =>
        ProductDetailsCubit(repository: _BrokenRepository(), productId: 1),
    act: (cubit) => cubit.load(),
    expect: () => [
      const ProductDetailsLoading(),
      const ProductDetailsError(UnknownException()),
    ],
    errors: () => [isA<StateError>()],
  );

  test('closing the cubit while it loads does not fail', () async {
    final gate = Completer<void>();
    final cubit = ProductDetailsCubit(
      repository: FakeProductsRepository(gate: gate),
      productId: 1,
    );

    final loading = cubit.load();
    await cubit.close(); // the user left the screen
    gate.complete(); // the answer arrives afterwards

    await expectLater(loading, completes);
  });
}

/// A repository with a bug: it throws something that is not an
/// [AppException], which a repository should never do.
class _BrokenRepository implements ProductsRepository {
  @override
  Future<Product> getProduct(int id) async => throw StateError('a bug');

  @override
  Future<ProductsPage> getProducts({required int skip, required int limit}) {
    throw UnimplementedError();
  }
}
