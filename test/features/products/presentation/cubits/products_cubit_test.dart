import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/features/products/data/mock_products.dart';
import 'package:e_commerce_learn/features/products/data/product_catalog.dart';
import 'package:e_commerce_learn/features/products/presentation/cubits/products_cubit.dart';
import 'package:e_commerce_learn/features/products/presentation/cubits/products_state.dart';

import '../../../../helpers/fake_products_repository.dart';

void main() {
  test('starts in the loading state', () {
    final cubit = ProductsCubit(repository: FakeProductsRepository());

    expect(cubit.state, const ProductsLoading());

    cubit.close();
  });

  late FakeProductsRepository repository;

  blocTest<ProductsCubit, ProductsState>(
    'load asks for the first page, then emits the products',
    setUp: () => repository = FakeProductsRepository(),
    build: () => ProductsCubit(repository: repository),
    act: (cubit) => cubit.load(),
    expect: () => [const ProductsLoading(), ProductsLoaded(mockProducts)],
    verify: (_) {
      expect(repository.requestedPages, [(skip: 0, limit: 30, category: null)]);
    },
  );

  blocTest<ProductsCubit, ProductsState>(
    'with a category, loads only that category',
    setUp: () => repository = FakeProductsRepository(),
    build: () => ProductsCubit(repository: repository, category: 'laptops'),
    act: (cubit) => cubit.load(),
    expect: () => [
      const ProductsLoading(),
      ProductsLoaded(productsInCategory(mockProducts, 'laptops')),
    ],
    verify: (_) {
      expect(repository.requestedPages, [
        (skip: 0, limit: 30, category: 'laptops'),
      ]);
    },
  );

  blocTest<ProductsCubit, ProductsState>(
    'an empty catalog emits the empty state',
    build: () =>
        ProductsCubit(repository: FakeProductsRepository(products: const [])),
    act: (cubit) => cubit.load(),
    expect: () => [const ProductsLoading(), const ProductsEmpty()],
  );

  blocTest<ProductsCubit, ProductsState>(
    'a failed load emits the error',
    build: () => ProductsCubit(
      repository: FakeProductsRepository(error: const NetworkException()),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      const ProductsLoading(),
      const ProductsError(NetworkException()),
    ],
  );

  blocTest<ProductsCubit, ProductsState>(
    'loading again after an error emits loading, then the products',
    setUp: () {
      repository = FakeProductsRepository(error: const NetworkException());
    },
    build: () => ProductsCubit(repository: repository),
    act: (cubit) async {
      await cubit.load();
      repository.error = null; // the connection is back
      await cubit.load();
    },
    expect: () => [
      const ProductsLoading(),
      const ProductsError(NetworkException()),
      const ProductsLoading(),
      ProductsLoaded(mockProducts),
    ],
  );

  blocTest<ProductsCubit, ProductsState>(
    'an error that is not an AppException is reported, and shown as unknown',
    build: () => ProductsCubit(
      repository: FakeProductsRepository(error: StateError('a bug')),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      const ProductsLoading(),
      const ProductsError(UnknownException()),
    ],
    errors: () => [isA<StateError>()],
  );

  test('closing the cubit while it loads does not fail', () async {
    final gate = Completer<void>();
    final cubit = ProductsCubit(repository: FakeProductsRepository(gate: gate));

    final loading = cubit.load();
    await cubit.close(); // the user left the screen
    gate.complete(); // the answer arrives afterwards

    await expectLater(loading, completes);
  });

  group('refresh', () {
    // A shorter catalog than the one on screen, to tell them apart.
    final twoProducts = mockProducts.take(2).toList();

    blocTest<ProductsCubit, ProductsState>(
      'replaces the products, without showing the loading state',
      setUp: () => repository = FakeProductsRepository(),
      build: () => ProductsCubit(repository: repository),
      seed: () => ProductsLoaded(mockProducts),
      act: (cubit) {
        repository.products = twoProducts; // the catalog changed meanwhile
        return cubit.refresh();
      },
      expect: () => [ProductsLoaded(twoProducts)],
    );

    blocTest<ProductsCubit, ProductsState>(
      'a failed refresh keeps the products and says why',
      build: () => ProductsCubit(
        repository: FakeProductsRepository(error: const NetworkException()),
      ),
      seed: () => ProductsLoaded(mockProducts),
      act: (cubit) => cubit.refresh(),
      expect: () => [
        ProductsLoaded(mockProducts, refreshError: const NetworkException()),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'failing twice in a row is reported twice',
      build: () => ProductsCubit(
        repository: FakeProductsRepository(error: const NetworkException()),
      ),
      seed: () => ProductsLoaded(mockProducts),
      act: (cubit) async {
        await cubit.refresh();
        await cubit.refresh();
      },
      expect: () => [
        ProductsLoaded(mockProducts, refreshError: const NetworkException()),
        ProductsLoaded(mockProducts),
        ProductsLoaded(mockProducts, refreshError: const NetworkException()),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'a refresh that finds no products emits the empty state',
      setUp: () => repository = FakeProductsRepository(),
      build: () => ProductsCubit(repository: repository),
      seed: () => ProductsLoaded(mockProducts),
      act: (cubit) {
        repository.products = const [];
        return cubit.refresh();
      },
      expect: () => [const ProductsEmpty()],
    );

    blocTest<ProductsCubit, ProductsState>(
      'does nothing unless the catalog is loaded',
      setUp: () => repository = FakeProductsRepository(),
      build: () => ProductsCubit(repository: repository),
      act: (cubit) => cubit.refresh(), // still in the loading state
      expect: () => <ProductsState>[],
      verify: (_) => expect(repository.getProductsCalls, 0),
    );

    test('closing the cubit while it refreshes does not fail', () async {
      final gate = Completer<void>();
      final cubit = ProductsCubit(
        repository: FakeProductsRepository(gate: gate),
      )..emit(ProductsLoaded(mockProducts));

      final refreshing = cubit.refresh();
      await cubit.close();
      gate.complete();

      await expectLater(refreshing, completes);
    });
  });

  test('the products of a loaded state cannot be changed', () {
    final state = ProductsLoaded(mockProducts.take(2).toList());

    expect(() => state.products.add(mockProducts[2]), throwsUnsupportedError);
  });
}
