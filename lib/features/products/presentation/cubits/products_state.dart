import 'package:equatable/equatable.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/data/product_sort.dart';

/// What the catalog is asked for: which [category] (or all) and which [sort].
final class ProductsQuery extends Equatable {
  const ProductsQuery({this.category, this.sort = ProductSort.featured});

  /// The category's slug, or `null` for the whole catalog.
  final String? category;
  final ProductSort sort;

  @override
  List<Object?> get props => [category, sort];
}

/// Everything the catalog can be showing.
///
/// Every state knows its [query], so the screen can always show what is
/// selected, even while loading or after an error.
sealed class ProductsState extends Equatable {
  const ProductsState({required this.query});

  final ProductsQuery query;

  @override
  List<Object?> get props => [query];
}

/// The catalog is being loaded.
final class ProductsLoading extends ProductsState {
  const ProductsLoading({super.query = const ProductsQuery()});
}

/// The catalog was loaded and has at least one product.
final class ProductsLoaded extends ProductsState {
  /// Keeps a copy of [products] that can't be changed, so nobody can add to
  /// the list of a state that was already emitted.
  ProductsLoaded(
    List<Product> products, {
    this.refreshError,
    super.query = const ProductsQuery(),
  }) : products = List.unmodifiable(products);

  final List<Product> products;

  /// Why the last pull-to-refresh failed, or `null`. When set, [products]
  /// are still the ones loaded before: the screen keeps showing them and
  /// tells the user the refresh didn't work.
  final AppException? refreshError;

  // `...super.props` keeps the query in the comparison. Forgetting it would
  // make two states with different queries look equal.
  @override
  List<Object?> get props => [...super.props, products, refreshError];
}

/// The catalog was loaded, but it has no products.
final class ProductsEmpty extends ProductsState {
  const ProductsEmpty({super.query = const ProductsQuery()});
}

/// Loading failed with [error].
final class ProductsError extends ProductsState {
  const ProductsError(this.error, {super.query = const ProductsQuery()});

  final AppException error;

  @override
  List<Object?> get props => [...super.props, error];
}
