import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/wishlist/data/wishlist_local_store.dart';
import 'package:e_commerce_learn/features/wishlist/data/models/wishlist.dart';

/// The wishlist, shared by the whole app.
///
/// Like `CartCubit`: the state is the [Wishlist] itself, every change is
/// made by [Wishlist]'s own methods, it's provided once, in `ShopLiteApp`,
/// above the router, and it starts from, and saves to, a [store].
class WishlistCubit extends Cubit<Wishlist> {
  /// Starts from the wishlist saved in [store], and saves every change to
  /// it. Without a store (in tests), it starts empty and saves nothing.
  WishlistCubit({WishlistLocalStore? store})
    : _store = store,
      super(store?.load() ?? const Wishlist.empty());

  final WishlistLocalStore? _store;

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

  /// Saves each new wishlist, as `CartCubit.onChange` does the cart.
  @override
  void onChange(Change<Wishlist> change) {
    super.onChange(change);
    unawaited(_store?.save(change.nextState));
  }
}
