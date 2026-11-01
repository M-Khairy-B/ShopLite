import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/core/errors/repository_errors.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';
import 'package:e_commerce_learn/features/products/presentation/cubits/product_details_state.dart';

/// Loads one product for the details screen.
///
/// Starts in [ProductDetailsLoading]; call [load] to fetch the product, and
/// call it again to retry after an error.
class ProductDetailsCubit extends Cubit<ProductDetailsState>
    with RepositoryErrors<ProductDetailsState> {
  ProductDetailsCubit({required this._repository, required this._productId})
    : super(const ProductDetailsLoading());

  final ProductsRepository _repository;
  final int _productId;

  Future<void> load() async {
    emit(const ProductDetailsLoading());

    final result = await _fetchProduct();

    // The cubit is closed when the user leaves the screen, possibly while we
    // were waiting. A closed cubit can't emit, so the result is dropped.
    if (isClosed) {
      return;
    }
    emit(result);
  }

  /// The state to show after asking the repository for the product.
  Future<ProductDetailsState> _fetchProduct() async {
    try {
      final product = await callRepository(
        () => _repository.getProduct(_productId),
      );
      return ProductDetailsLoaded(product);
    } on AppException catch (error) {
      return ProductDetailsError(error);
    }
  }
}
