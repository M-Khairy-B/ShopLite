import 'package:equatable/equatable.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';

/// Everything the search screen can be showing.
///
/// Every state knows the [query] it is about (trimmed). That is how an answer
/// that arrives late can tell whether it is still wanted.
sealed class SearchState extends Equatable {
  const SearchState({required this.query});

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Nothing typed yet (or the field was cleared). Its [query] is empty.
final class SearchIdle extends SearchState {
  const SearchIdle() : super(query: '');
}

/// The results for [query] are on their way.
final class SearchLoading extends SearchState {
  const SearchLoading({required super.query});
}

/// [products] match [query]: the first ones, if there are more than fit in
/// one answer ([total] says how many match in all).
final class SearchLoaded extends SearchState {
  SearchLoaded(
    List<Product> products, {
    required this.total,
    required super.query,
  }) : products = List.unmodifiable(products);

  final List<Product> products;
  final int total;

  @override
  List<Object?> get props => [...super.props, products, total];
}

/// Nothing matches [query].
final class SearchEmpty extends SearchState {
  const SearchEmpty({required super.query});
}

/// Searching for [query] failed with [error].
final class SearchError extends SearchState {
  const SearchError(this.error, {required super.query});

  final AppException error;

  @override
  List<Object?> get props => [...super.props, error];
}
