import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/features/products/data/mock_products.dart';
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
      expect(repository.requestedPages, [(skip: 0, limit: 30)]);
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

  test('the products of a loaded state cannot be changed', () {
    final state = ProductsLoaded(mockProducts.take(2).toList());

    expect(() => state.products.add(mockProducts[2]), throwsUnsupportedError);
  });
}
