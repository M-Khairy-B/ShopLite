import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/features/products/data/models/products_page.dart';
import 'package:e_commerce_learn/features/products/data/product_sort.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';
import 'package:e_commerce_learn/features/products/presentation/cubits/products_state.dart';

/// Loads the catalog: all products (Home), or one category's products.
///
/// Starts in [ProductsLoading]; call [load] to fetch the catalog, and call it
/// again to retry after an error.
class ProductsCubit extends Cubit<ProductsState> {
  /// With a [category] (its slug), the cubit starts with only that
  /// category's products.
  ProductsCubit({required this._repository, String? category})
    : super(ProductsLoading(query: ProductsQuery(category: category)));

  /// How many products each page has: the first one, and each [loadMore].
  static const pageSize = 30;

  final ProductsRepository _repository;

  /// Loads (or, after an error, reloads) what is currently selected.
  Future<void> load() => _show(state.query);

  /// Shows only [category]'s products (its slug), or the whole catalog for
  /// `null`, keeping the sort. Does nothing if it is already selected.
  Future<void> selectCategory(String? category) async {
    if (category == state.query.category) {
      return;
    }
    await _show(ProductsQuery(category: category, sort: state.query.sort));
  }

  /// Shows the catalog in [sort] order, keeping the category. Does nothing
  /// if that order is already chosen.
  Future<void> changeSort(ProductSort sort) async {
    if (sort == state.query.sort) {
      return;
    }
    await _show(ProductsQuery(category: state.query.category, sort: sort));
  }

  /// Shows the loading state for [query], then its first page.
  Future<void> _show(ProductsQuery query) async {
    emit(ProductsLoading(query: query));

    final result = await _fetchFirstPage(query);

    // Dropped if, while we were waiting, the cubit was closed (its screen
    // went away; a closed cubit can't emit) or the user chose something
    // else: an older, slower answer must never replace a newer choice.
    if (isClosed || state.query != query) {
      return;
    }
    emit(result);
  }

  /// Loads the next page and adds it after the products already shown
  /// (infinite scroll). Does nothing unless the catalog is loaded, has more,
  /// and isn't already loading more, so it is safe to call often.
  ///
  /// If it fails, the products stay and [ProductsLoaded.loadMoreError] says
  /// why. Then it does nothing until [retryLoadMore] is called: the screen
  /// calls this while the user scrolls, and scrolling shouldn't send request
  /// after request while offline. (The screen can't stop that itself: it
  /// may still be showing the state from before the failure.)
  Future<void> loadMore() async {
    final current = state;
    if (current is! ProductsLoaded ||
        !current.hasMore ||
        current.isLoadingMore ||
        current.loadMoreError != null) {
      return;
    }
    await _loadNextPage(current);
  }

  /// Tries [loadMore] again after it failed (the user tapped "Try again").
  /// Does nothing if it hasn't failed.
  Future<void> retryLoadMore() async {
    final current = state;
    if (current is! ProductsLoaded || current.loadMoreError == null) {
      return;
    }
    await _loadNextPage(current);
  }

  /// Marks [current] as loading more, then shows it with the next page added
  /// (or with the reason that failed).
  Future<void> _loadNextPage(ProductsLoaded current) async {
    // Emitted before the first await, so a call that comes while this one
    // waits already sees "loading more". Also forgets an earlier load-more
    // error: this is a new attempt.
    emit(
      ProductsLoaded(
        current.products,
        hasMore: true,
        isLoadingMore: true,
        query: current.query,
      ),
    );

    final result = await _withNextPage(current);

    // As in _show: closed, or the user chose something else meanwhile.
    if (isClosed || state.query != current.query) {
      return;
    }
    emit(result);
  }

  /// [current] with the next page added, or with the reason it failed.
  Future<ProductsLoaded> _withNextPage(ProductsLoaded current) async {
    try {
      final page = await _fetchPage(
        current.query,
        skip: current.products.length,
      );
      // If the catalog changed between two pages, the next page can start
      // with a product that is already shown. Showing it twice would look
      // broken (and give two grid items the same key).
      final shownIds = {for (final product in current.products) product.id};
      return ProductsLoaded(
        [
          ...current.products,
          ...page.products.where((product) => !shownIds.contains(product.id)),
        ],
        hasMore: page.hasMore,
        query: current.query,
      );
    } on AppException catch (error) {
      return ProductsLoaded(
        current.products,
        hasMore: true,
        loadMoreError: error,
        query: current.query,
      );
    }
  }

  /// Reloads the catalog while the current products stay on screen
  /// (pull-to-refresh). Does nothing unless the catalog is loaded.
  ///
  /// There's no loading state: the refresh indicator shows its own spinner
  /// until this Future completes. If the refresh fails, the products stay
  /// and [ProductsLoaded.refreshError] says why.
  Future<void> refresh() async {
    final current = state;
    if (current is! ProductsLoaded) {
      return;
    }

    // Forget the previous refresh error first. Otherwise failing again
    // would emit a state equal to the current one, which is skipped, and the
    // screen would never hear about the second failure.
    emit(
      ProductsLoaded(
        current.products,
        hasMore: current.hasMore,
        query: current.query,
      ),
    );

    // A successful refresh starts again from the first page.
    final result = await _fetchFirstPage(current.query);
    // As in _show: closed, or the user chose something else meanwhile.
    if (isClosed || state.query != current.query) {
      return;
    }
    emit(switch (result) {
      ProductsError(:final error) => ProductsLoaded(
        current.products,
        hasMore: current.hasMore,
        refreshError: error,
        query: current.query,
      ),
      _ => result,
    });
  }

  /// The state to show after asking the repository for the first page of
  /// [query].
  Future<ProductsState> _fetchFirstPage(ProductsQuery query) async {
    try {
      final page = await _fetchPage(query, skip: 0);
      return page.products.isEmpty
          ? ProductsEmpty(query: query)
          : ProductsLoaded(page.products, hasMore: page.hasMore, query: query);
    } on AppException catch (error) {
      return ProductsError(error, query: query);
    }
  }

  /// One page of [query], after the first [skip] products.
  ///
  /// Throws AppExceptions only. The repository promises that, so anything
  /// else is a bug: it is reported (to BlocObserver.onError) and turned into
  /// an UnknownException, which still gives the user a way to retry.
  Future<ProductsPage> _fetchPage(
    ProductsQuery query, {
    required int skip,
  }) async {
    try {
      // `return await`, not just `return`: without the await, an error from
      // the Future would arrive after this try had already finished.
      return await _repository.getProducts(
        skip: skip,
        limit: pageSize,
        category: query.category,
        sort: query.sort,
      );
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      if (!isClosed) {
        addError(error, stackTrace);
      }
      throw const UnknownException();
    }
  }
}
