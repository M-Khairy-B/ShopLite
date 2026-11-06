import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/wishlist/data/models/wishlist.dart';

/// The wishlist, shared by the whole app.
///
/// Like `CartCubit`: the state is the [Wishlist] itself, every change is
/// made by [Wishlist]'s own methods, and it's provided once, in
/// `ShopLiteApp`, above the router.
class WishlistCubit extends Cubit<Wishlist> {
  WishlistCubit() : super(const Wishlist.empty());

  /// Saves [product], or removes it if it's saved: a tap on a heart.
  ///
  /// Always a change, so it needs no "nothing changed" check.
  void toggle(Product product) {
    emit(state.toggle(product));
  }

  /// Removes the product with [productId], from the wishlist screen.
  void remove(int productId) {
    if (!state.contains(productId)) {
      return; // not saved
    }
    emit(state.remove(productId));
  }
}
