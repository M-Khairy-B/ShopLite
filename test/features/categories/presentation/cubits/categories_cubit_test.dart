import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:e_commerce_learn/features/categories/presentation/cubits/categories_state.dart';
import 'package:e_commerce_learn/features/products/data/models/product_category.dart';

import '../../../../helpers/fake_products_repository.dart';

void main() {
  const categories = [
    ProductCategory(slug: 'beauty', name: 'Beauty'),
    ProductCategory(slug: 'home-decoration', name: 'Home Decoration'),
  ];

  test('starts in the loading state', () {
    final cubit = CategoriesCubit(repository: FakeProductsRepository());

    expect(cubit.state, const CategoriesLoading());

    cubit.close();
  });

  blocTest<CategoriesCubit, CategoriesState>(
    'load emits loading, then the categories',
    build: () => CategoriesCubit(
      repository: FakeProductsRepository(categories: categories),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [const CategoriesLoading(), CategoriesLoaded(categories)],
  );

  blocTest<CategoriesCubit, CategoriesState>(
    'no categories emits the empty state',
    build: () =>
        CategoriesCubit(repository: FakeProductsRepository(categories: [])),
    act: (cubit) => cubit.load(),
    expect: () => [const CategoriesLoading(), const CategoriesEmpty()],
  );

  late FakeProductsRepository repository;

  blocTest<CategoriesCubit, CategoriesState>(
    'loading again after an error emits loading, then the categories',
    setUp: () {
      repository = FakeProductsRepository(
        categories: categories,
        error: const NetworkException(),
      );
    },
    build: () => CategoriesCubit(repository: repository),
    act: (cubit) async {
      await cubit.load();
      repository.error = null; // the connection is back
      await cubit.load();
    },
    expect: () => [
      const CategoriesLoading(),
      const CategoriesError(NetworkException()),
      const CategoriesLoading(),
      CategoriesLoaded(categories),
    ],
  );

  blocTest<CategoriesCubit, CategoriesState>(
    'an error that is not an AppException is reported, and shown as unknown',
    build: () => CategoriesCubit(
      repository: FakeProductsRepository(error: StateError('a bug')),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      const CategoriesLoading(),
      const CategoriesError(UnknownException()),
    ],
    errors: () => [isA<StateError>()],
  );

  group('reloadIfFailed', () {
    blocTest<CategoriesCubit, CategoriesState>(
      'after an error, loads the categories again',
      setUp: () {
        repository = FakeProductsRepository(
          categories: categories,
          error: const NetworkException(),
        );
      },
      build: () => CategoriesCubit(repository: repository),
      act: (cubit) async {
        await cubit.load();
        repository.error = null; // the connection is back
        await cubit.reloadIfFailed();
      },
      skip: 2, // the first load: loading, then the error
      expect: () => [const CategoriesLoading(), CategoriesLoaded(categories)],
    );

    blocTest<CategoriesCubit, CategoriesState>(
      'does nothing once the categories are loaded',
      setUp: () => repository = FakeProductsRepository(categories: categories),
      build: () => CategoriesCubit(repository: repository),
      act: (cubit) async {
        await cubit.load();
        await cubit.reloadIfFailed();
      },
      skip: 2, // the first load
      expect: () => <CategoriesState>[],
      verify: (_) => expect(repository.getCategoriesCalls, 1),
    );

    test('does nothing while the categories are loading', () async {
      final gate = Completer<void>();
      final repository = FakeProductsRepository(gate: gate);
      final cubit = CategoriesCubit(repository: repository);

      final loading = cubit.load();
      await cubit.reloadIfFailed();
      gate.complete();
      await loading;

      expect(repository.getCategoriesCalls, 1);
      await cubit.close();
    });
  });

  test('closing the cubit while it loads does not fail', () async {
    final gate = Completer<void>();
    final cubit = CategoriesCubit(
      repository: FakeProductsRepository(gate: gate),
    );

    final loading = cubit.load();
    await cubit.close();
    gate.complete();

    await expectLater(loading, completes);
  });
}
