import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';
import 'package:e_commerce_learn/features/products/presentation/cubits/products_state.dart';

/// Loads the home catalog.
///
/// Starts in [ProductsLoading]; call [load] to fetch the catalog, and call it
/// again to retry after an error.
class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit({required this._repository}) : super(const ProductsLoading());

  /// How many products to load. Only the first page for now: Phase 5 loads
  /// more while the user scrolls.
  static const pageSize = 30;

  final ProductsRepository _repository;

  Future<void> load() async {
    emit(const ProductsLoading());

    final result = await _fetchFirstPage();

    // The cubit is closed when its screen goes away, possibly while we were
    // waiting. A closed cubit can't emit, so the result is dropped.
    if (isClosed) {
      return;
    }
    emit(result);
  }

  /// The state to show after asking the repository for the first page.
  Future<ProductsState> _fetchFirstPage() async {
    try {
      final page = await _repository.getProducts(skip: 0, limit: pageSize);
      return page.products.isEmpty
          ? const ProductsEmpty()
          : ProductsLoaded(page.products);
    } on AppException catch (error) {
      return ProductsError(error);
    } catch (error, stackTrace) {
      // The repository promises AppExceptions only, so this is a bug.
      // Report it (to BlocObserver.onError), but still give the user a way
      // to retry.
      if (!isClosed) {
        addError(error, stackTrace);
      }
      return const ProductsError(UnknownException());
    }
  }
}
