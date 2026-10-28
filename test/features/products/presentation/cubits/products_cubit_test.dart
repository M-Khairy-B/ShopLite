import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/features/products/data/product_sort.dart';
import 'package:e_commerce_learn/features/products/presentation/cubits/products_cubit.dart';
import 'package:e_commerce_learn/features/products/presentation/cubits/products_state.dart';

import '../../../../helpers/fake_catalog.dart';
import '../../../../helpers/fake_products_repository.dart';
import '../../../../helpers/mock_products.dart';

void main() {
  const laptops = ProductsQuery(category: 'laptops');
  final laptopProducts = productsInCategory(mockProducts, 'laptops');

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
      expect(repository.requestedPages, [
        (skip: 0, limit: 30, category: null, sort: ProductSort.featured),
      ]);
    },
  );

  blocTest<ProductsCubit, ProductsState>(
    'with a category, loads only that category',
    setUp: () => repository = FakeProductsRepository(),
    build: () => ProductsCubit(repository: repository, category: 'laptops'),
    act: (cubit) => cubit.load(),
    expect: () => [
      const ProductsLoading(query: laptops),
      ProductsLoaded(laptopProducts, query: laptops),
    ],
    verify: (_) {
      expect(repository.requestedPages, [
        (skip: 0, limit: 30, category: 'laptops', sort: ProductSort.featured),
      ]);
    },
  );

  group('choosing what to show', () {
    blocTest<ProductsCubit, ProductsState>(
      'selecting a category loads that category',
      build: () => ProductsCubit(repository: FakeProductsRepository()),
      seed: () => ProductsLoaded(mockProducts),
      act: (cubit) => cubit.selectCategory('laptops'),
      expect: () => [
        const ProductsLoading(query: laptops),
        ProductsLoaded(laptopProducts, query: laptops),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'selecting All (null) loads the whole catalog again',
      build: () => ProductsCubit(repository: FakeProductsRepository()),
      seed: () => ProductsLoaded(laptopProducts, query: laptops),
      act: (cubit) => cubit.selectCategory(null),
      expect: () => [const ProductsLoading(), ProductsLoaded(mockProducts)],
    );

    blocTest<ProductsCubit, ProductsState>(
      'selecting the category that is already selected does nothing',
      setUp: () => repository = FakeProductsRepository(),
      build: () => ProductsCubit(repository: repository),
      seed: () => ProductsLoaded(laptopProducts, query: laptops),
      act: (cubit) => cubit.selectCategory('laptops'),
      expect: () => <ProductsState>[],
      verify: (_) => expect(repository.getProductsCalls, 0),
    );

    blocTest<ProductsCubit, ProductsState>(
      'changing the sort reloads in that order, keeping the category',
      build: () => ProductsCubit(repository: FakeProductsRepository()),
      seed: () => ProductsLoaded(laptopProducts, query: laptops),
      act: (cubit) => cubit.changeSort(ProductSort.priceLowToHigh),
      expect: () {
        const cheapLaptopsFirst = ProductsQuery(
          category: 'laptops',
          sort: ProductSort.priceLowToHigh,
        );
        return [
          const ProductsLoading(query: cheapLaptopsFirst),
          ProductsLoaded(
            sortProducts(laptopProducts, ProductSort.priceLowToHigh),
            query: cheapLaptopsFirst,
          ),
        ];
      },
    );

    blocTest<ProductsCubit, ProductsState>(
      'choosing the sort that is already chosen does nothing',
      setUp: () => repository = FakeProductsRepository(),
      build: () => ProductsCubit(repository: repository),
      seed: () => ProductsLoaded(mockProducts),
      act: (cubit) => cubit.changeSort(ProductSort.featured),
      expect: () => <ProductsState>[],
      verify: (_) => expect(repository.getProductsCalls, 0),
    );

    test('an answer for an earlier choice is ignored', () async {
      final firstAnswer = Completer<void>();
      final repository = FakeProductsRepository(gate: firstAnswer);
      final cubit = ProductsCubit(repository: repository)
        ..emit(ProductsLoaded(mockProducts));

      // The user taps "Laptops"; that answer is slow...
      final laptopsLoading = cubit.selectCategory('laptops');
      // ...so they tap "Beauty", which is answered at once.
      repository.gate = null;
      await cubit.selectCategory('beauty');
      // Now the old "Laptops" answer arrives, last.
      firstAnswer.complete();
      await laptopsLoading;

      expect(
        cubit.state,
        ProductsLoaded(
          productsInCategory(mockProducts, 'beauty'),
          query: const ProductsQuery(category: 'beauty'),
        ),
      );
      await cubit.close();
    });
  });

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

    blocTest<ProductsCubit, ProductsState>(
      'keeps the selected category and sort',
      setUp: () => repository = FakeProductsRepository(),
      build: () => ProductsCubit(repository: repository),
      seed: () => ProductsLoaded(
        laptopProducts,
        query: const ProductsQuery(
          category: 'laptops',
          sort: ProductSort.topRated,
        ),
      ),
      act: (cubit) => cubit.refresh(),
      verify: (_) {
        expect(repository.requestedPages, [
          (skip: 0, limit: 30, category: 'laptops', sort: ProductSort.topRated),
        ]);
      },
    );

    test('a refresh answer for an earlier choice is ignored', () async {
      final slowRefresh = Completer<void>();
      final repository = FakeProductsRepository(gate: slowRefresh);
      final cubit = ProductsCubit(repository: repository)
        ..emit(ProductsLoaded(mockProducts));

      final refreshing = cubit.refresh();
      // While it refreshes, the user picks "Laptops", answered at once.
      repository.gate = null;
      await cubit.selectCategory('laptops');
      slowRefresh.complete();
      await refreshing;

      expect(cubit.state, ProductsLoaded(laptopProducts, query: laptops));
      await cubit.close();
    });

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

  group('load more', () {
    // 45 products: page 1 is products 1–30, page 2 is products 31–45.
    final catalog = generatedProducts(45);
    final firstPage = catalog.take(30).toList();

    blocTest<ProductsCubit, ProductsState>(
      'the first page says whether more products exist',
      build: () =>
          ProductsCubit(repository: FakeProductsRepository(products: catalog)),
      act: (cubit) => cubit.load(),
      expect: () => [
        const ProductsLoading(),
        ProductsLoaded(firstPage, hasMore: true),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'asks for the next page and adds it after the loaded products',
      setUp: () => repository = FakeProductsRepository(products: catalog),
      build: () => ProductsCubit(repository: repository),
      seed: () => ProductsLoaded(firstPage, hasMore: true),
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        ProductsLoaded(firstPage, hasMore: true, isLoadingMore: true),
        ProductsLoaded(catalog), // all 45, and nothing more after them
      ],
      verify: (_) {
        expect(repository.requestedPages, [
          (skip: 30, limit: 30, category: null, sort: ProductSort.featured),
        ]);
      },
    );

    blocTest<ProductsCubit, ProductsState>(
      'asks for the next page of the same category and sort',
      setUp: () => repository = FakeProductsRepository(products: catalog),
      build: () => ProductsCubit(repository: repository),
      seed: () => ProductsLoaded(
        firstPage,
        hasMore: true,
        query: const ProductsQuery(
          category: 'beauty',
          sort: ProductSort.priceLowToHigh,
        ),
      ),
      act: (cubit) => cubit.loadMore(),
      verify: (_) {
        expect(repository.requestedPages, [
          (
            skip: 30,
            limit: 30,
            category: 'beauty',
            sort: ProductSort.priceLowToHigh,
          ),
        ]);
      },
    );

    blocTest<ProductsCubit, ProductsState>(
      'does nothing when there is nothing more',
      setUp: () => repository = FakeProductsRepository(products: catalog),
      build: () => ProductsCubit(repository: repository),
      seed: () => ProductsLoaded(catalog),
      act: (cubit) => cubit.loadMore(),
      expect: () => <ProductsState>[],
      verify: (_) => expect(repository.getProductsCalls, 0),
    );

    blocTest<ProductsCubit, ProductsState>(
      'does nothing while the next page is already loading',
      setUp: () => repository = FakeProductsRepository(products: catalog),
      build: () => ProductsCubit(repository: repository),
      seed: () => ProductsLoaded(firstPage, hasMore: true, isLoadingMore: true),
      act: (cubit) => cubit.loadMore(),
      expect: () => <ProductsState>[],
      verify: (_) => expect(repository.getProductsCalls, 0),
    );

    blocTest<ProductsCubit, ProductsState>(
      'a failed load more keeps the products and says why',
      build: () => ProductsCubit(
        repository: FakeProductsRepository(
          products: catalog,
          error: const NetworkException(),
        ),
      ),
      seed: () => ProductsLoaded(firstPage, hasMore: true),
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        ProductsLoaded(firstPage, hasMore: true, isLoadingMore: true),
        ProductsLoaded(
          firstPage,
          hasMore: true,
          loadMoreError: const NetworkException(),
        ),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'trying again after a failure forgets the error and adds the page',
      build: () =>
          ProductsCubit(repository: FakeProductsRepository(products: catalog)),
      seed: () => ProductsLoaded(
        firstPage,
        hasMore: true,
        loadMoreError: const NetworkException(),
      ),
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        ProductsLoaded(firstPage, hasMore: true, isLoadingMore: true),
        ProductsLoaded(catalog),
      ],
    );

    blocTest<ProductsCubit, ProductsState>(
      'a product that is already shown is not added twice',
      // A new product was added at the start of the catalog after page 1
      // was loaded, so everything moved one place: page 2 now starts with
      // product 30, which is already on screen.
      build: () => ProductsCubit(
        repository: FakeProductsRepository(
          products: [mockProducts.first, ...catalog],
        ),
      ),
      seed: () => ProductsLoaded(firstPage, hasMore: true),
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        ProductsLoaded(firstPage, hasMore: true, isLoadingMore: true),
        ProductsLoaded(catalog),
      ],
    );

    test('an answer for an earlier choice is ignored', () async {
      final slowPage = Completer<void>();
      final repository = FakeProductsRepository(
        products: catalog,
        gate: slowPage,
      );
      final cubit = ProductsCubit(repository: repository)
        ..emit(ProductsLoaded(firstPage, hasMore: true));

      final loadingMore = cubit.loadMore();
      // While page 2 loads, the user picks "Beauty", answered at once.
      repository.gate = null;
      await cubit.selectCategory('beauty');
      slowPage.complete();
      await loadingMore;

      expect(
        cubit.state,
        ProductsLoaded(
          firstPage,
          hasMore: true,
          query: const ProductsQuery(category: 'beauty'),
        ),
      );
      await cubit.close();
    });

    test('closing the cubit while it loads more does not fail', () async {
      final gate = Completer<void>();
      final cubit = ProductsCubit(
        repository: FakeProductsRepository(products: catalog, gate: gate),
      )..emit(ProductsLoaded(firstPage, hasMore: true));

      final loadingMore = cubit.loadMore();
      await cubit.close();
      gate.complete();

      await expectLater(loadingMore, completes);
    });

    blocTest<ProductsCubit, ProductsState>(
      'a failed refresh keeps every loaded page and whether there is more',
      build: () => ProductsCubit(
        repository: FakeProductsRepository(
          products: catalog,
          error: const NetworkException(),
        ),
      ),
      seed: () => ProductsLoaded(firstPage, hasMore: true),
      act: (cubit) => cubit.refresh(),
      expect: () => [
        ProductsLoaded(
          firstPage,
          hasMore: true,
          refreshError: const NetworkException(),
        ),
      ],
    );
  });

  test('the products of a loaded state cannot be changed', () {
    final state = ProductsLoaded(mockProducts.take(2).toList());

    expect(() => state.products.add(mockProducts[2]), throwsUnsupportedError);
  });
}
