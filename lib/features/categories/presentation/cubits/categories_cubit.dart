import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/features/categories/presentation/cubits/categories_state.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';

/// Loads the list of categories for the Categories tab.
///
/// Starts in [CategoriesLoading]; call [load] to fetch the categories, and
/// call it again to retry after an error.
class CategoriesCubit extends Cubit<CategoriesState> {
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

  /// The state to show after asking the repository for the categories.
  Future<CategoriesState> _fetchCategories() async {
    try {
      final categories = await _repository.getCategories();
      return categories.isEmpty
          ? const CategoriesEmpty()
          : CategoriesLoaded(categories);
    } on AppException catch (error) {
      return CategoriesError(error);
    } catch (error, stackTrace) {
      // The repository promises AppExceptions only, so this is a bug.
      // Report it (to BlocObserver.onError), but still give the user a way
      // to retry.
      if (!isClosed) {
        addError(error, stackTrace);
      }
      return const CategoriesError(UnknownException());
    }
  }
}
