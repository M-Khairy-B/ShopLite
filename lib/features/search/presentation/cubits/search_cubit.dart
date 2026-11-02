import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/core/errors/repository_errors.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';
import 'package:e_commerce_learn/features/search/presentation/cubits/search_state.dart';

/// Searches the catalog while the user types.
///
/// Starts in [SearchIdle]. The screen calls [queryChanged] on every
/// keystroke; the cubit searches once the user pauses (debounce), so typing
/// "phone" sends one request, not five.
class SearchCubit extends Cubit<SearchState>
    with RepositoryErrors<SearchState> {
  SearchCubit({required this._repository}) : super(const SearchIdle());

  /// How long typing must pause before the search is sent.
  static const debounce = Duration(milliseconds: 400);

  /// How many results one search shows at most.
  static const resultLimit = 30;

  final ProductsRepository _repository;

  /// The search waiting for the pause to be over, if any.
  Timer? _debounceTimer;

  /// The text in the search field changed to [text].
  ///
  /// Each keystroke cancels the search that was waiting and starts waiting
  /// again: only a pause of [debounce] lets a search through. Clearing the
  /// field goes back to idle at once.
  void queryChanged(String text) {
    _debounceTimer?.cancel();
    final query = text.trim();
    // Already showing (or loading) this query, e.g. after typing a space.
    if (query == state.query) {
      return;
    }
    if (query.isEmpty) {
      emit(const SearchIdle());
      return;
    }
    _debounceTimer = Timer(debounce, () => _search(query));
  }

  /// Searches for [text] right away (the keyboard's search button: the user
  /// is done typing, so there is nothing to wait for).
  Future<void> submit(String text) async {
    _debounceTimer?.cancel();
    final query = text.trim();
    if (query.isEmpty || query == state.query) {
      return;
    }
    await _search(query);
  }

  /// Searches again after an error (the user tapped "Try again"). Does
  /// nothing if the search hasn't failed.
  Future<void> retry() async {
    if (state case SearchError(:final query)) {
      await _search(query);
    }
  }

  /// Shows the loading state for [query], then its results.
  Future<void> _search(String query) async {
    emit(SearchLoading(query: query));

    final result = await _fetchResults(query);

    // Dropped if, while we were waiting, the cubit was closed or the user
    // typed something else (or cleared the field): an older, slower answer
    // must never replace a newer search.
    if (isClosed || state.query != query) {
      return;
    }
    emit(result);
  }

  /// The state to show after asking the repository for [query].
  Future<SearchState> _fetchResults(String query) async {
    try {
      final page = await callRepository(
        () => _repository.searchProducts(query, limit: resultLimit),
      );
      return page.products.isEmpty
          ? SearchEmpty(query: query)
          : SearchLoaded(page.products, total: page.total, query: query);
    } on AppException catch (error) {
      return SearchError(error, query: query);
    }
  }

  @override
  Future<void> close() {
    // A timer isn't part of the cubit: closing the cubit doesn't stop it.
    // Without this, a search could start after the screen is gone, and its
    // emit would fail on the closed cubit.
    _debounceTimer?.cancel();
    return super.close();
  }
}
