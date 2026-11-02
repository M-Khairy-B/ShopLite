import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/core/errors/repository_errors.dart';
import 'package:e_commerce_learn/features/categories/presentation/cubits/categories_state.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';

/// Loads the list of categories for the Categories tab.
///
/// Starts in [CategoriesLoading]; call [load] to fetch the categories, and
/// call it again to retry after an error.
class CategoriesCubit extends Cubit<CategoriesState>
    with RepositoryErrors<CategoriesState> {
  CategoriesCubit({required this._repository})
    : super(const CategoriesLoading());

  final ProductsRepository _repository;

  Future<void> load() async {
    emit(const CategoriesLoading());

    final result = await _fetchCategories();

    // The cubit is closed when its screen goes away, possibly while we were
    // waiting. A closed cubit can't emit, so the result is dropped.
    if (isClosed) {
      return;
    }
    emit(result);
  }

  /// Loads again, but only after an error: for screens where the categories
  /// are extra, and come back when the user retries something else.
  ///
  /// Does nothing while loading (that answer is on its way) or once loaded:
  /// they rarely change, and reloading would hide them for a moment.
  Future<void> reloadIfFailed() async {
    if (state is! CategoriesError) {
      return;
    }
    await load();
  }

  /// The state to show after asking the repository for the categories.
  Future<CategoriesState> _fetchCategories() async {
    try {
      final categories = await callRepository(_repository.getCategories);
      return categories.isEmpty
          ? const CategoriesEmpty()
          : CategoriesLoaded(categories);
    } on AppException catch (error) {
      return CategoriesError(error);
    }
  }
}
