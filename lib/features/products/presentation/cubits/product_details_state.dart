import 'package:equatable/equatable.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';

/// Everything the product details screen can be showing.
///
/// `sealed`, so a `switch` over it must handle every state, and adding a
/// state makes each such `switch` fail to compile until it handles it.
/// [Equatable] compares states by their [props], so emitting a state equal to
/// the current one is skipped.
sealed class ProductDetailsState extends Equatable {
  const ProductDetailsState();

  @override
  List<Object?> get props => [];
}

/// The product is being loaded.
final class ProductDetailsLoading extends ProductDetailsState {
  const ProductDetailsLoading();
}

/// The product was loaded.
final class ProductDetailsLoaded extends ProductDetailsState {
  const ProductDetailsLoaded(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}

/// Loading failed with [error], for example a [NotFoundException].
final class ProductDetailsError extends ProductDetailsState {
  const ProductDetailsError(this.error);

  final AppException error;

  @override
  List<Object?> get props => [error];
}
