import 'package:equatable/equatable.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/features/products/data/models/product_category.dart';

/// Everything the Categories tab can be showing.
sealed class CategoriesState extends Equatable {
  const CategoriesState();

  @override
  List<Object?> get props => [];
}

/// The categories are being loaded.
final class CategoriesLoading extends CategoriesState {
  const CategoriesLoading();
}

/// The categories were loaded, and there is at least one.
final class CategoriesLoaded extends CategoriesState {
  CategoriesLoaded(List<ProductCategory> categories)
    : categories = List.unmodifiable(categories);

  final List<ProductCategory> categories;

  @override
  List<Object?> get props => [categories];
}

/// The categories were loaded, but there are none.
final class CategoriesEmpty extends CategoriesState {
  const CategoriesEmpty();
}

/// Loading failed with [error].
final class CategoriesError extends CategoriesState {
  const CategoriesError(this.error);

  final AppException error;

  @override
  List<Object?> get props => [error];
}
