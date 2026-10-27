import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
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

  /// How many products to load. Only the first page for now: Phase 5 loads
  /// more while the user scrolls.
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
    emit(ProductsLoaded(current.products, query: current.query));

    final result = await _fetchFirstPage(current.query);
    // As in _show: closed, or the user chose something else meanwhile.
    if (isClosed || state.query != current.query) {
      return;
    }
    emit(switch (result) {
      ProductsError(:final error) => ProductsLoaded(
        current.products,
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
      final page = await _repository.getProducts(
        skip: 0,
        limit: pageSize,
        category: query.category,
        sort: query.sort,
      );
      return page.products.isEmpty
          ? ProductsEmpty(query: query)
          : ProductsLoaded(page.products, query: query);
    } on AppException catch (error) {
      return ProductsError(error, query: query);
    } catch (error, stackTrace) {
      // The repository promises AppExceptions only, so this is a bug.
      // Report it (to BlocObserver.onError), but still give the user a way
      // to retry.
      if (!isClosed) {
        addError(error, stackTrace);
      }
      return ProductsError(const UnknownException(), query: query);
    }
  }
}
