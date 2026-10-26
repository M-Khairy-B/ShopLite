import 'package:equatable/equatable.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';

/// Everything the home catalog can be showing.
sealed class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object?> get props => [];
}

/// The catalog is being loaded.
final class ProductsLoading extends ProductsState {
  const ProductsLoading();
}

/// The catalog was loaded and has at least one product.
final class ProductsLoaded extends ProductsState {
  /// Keeps a copy of [products] that can't be changed, so nobody can add to
  /// the list of a state that was already emitted.
  ProductsLoaded(List<Product> products, {this.refreshError})
    : products = List.unmodifiable(products);

  final List<Product> products;

  /// Why the last pull-to-refresh failed, or `null`. When set, [products]
  /// are still the ones loaded before: the screen keeps showing them and
  /// tells the user the refresh didn't work.
  final AppException? refreshError;

  @override
  List<Object?> get props => [products, refreshError];
}

/// The catalog was loaded, but it has no products.
final class ProductsEmpty extends ProductsState {
  const ProductsEmpty();
}

/// Loading failed with [error].
final class ProductsError extends ProductsState {
  const ProductsError(this.error);

  final AppException error;

  @override
  List<Object?> get props => [error];
}
