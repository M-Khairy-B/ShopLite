import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_learn/features/cart/data/models/cart.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';

/// The shopping cart, shared by the whole app.
///
/// The state is the [Cart] itself: there is no loading or error state,
/// because nothing here waits for the network. Every method emits a new
/// cart made by [Cart]'s own methods, so the cart rules live in one place.
///
/// A change that wouldn't change anything emits nothing. Each method checks
/// that itself: Cubit skips a state equal to the current one only after its
/// first emit, so a new cubit would still emit an equal, empty cart.
///
/// Provided once, in `ShopLiteApp`, above the router: every screen, sheet
/// and dialog finds the same cubit. Provided inside a route, each screen
/// would get its own, separate cart.
class CartCubit extends Cubit<Cart> {
  CartCubit() : super(const Cart.empty());

  /// Adds one [product], or [quantity] of it.
  void add(Product product, {int quantity = 1}) {
    emit(state.add(product, quantity: quantity));
  }

  /// Takes the product's whole line out of the cart.
  void remove(int productId) {
    if (state.quantityOf(productId) == 0) {
      return; // not in the cart
    }
    emit(state.remove(productId));
  }

  /// One more of a product that is already in the cart, up to
  /// [maxQuantityPerItem].
  void increment(int productId) {
    final quantity = state.quantityOf(productId);
    if (quantity == 0) {
      return; // not in the cart: "+" only exists on a cart line
    }
    if (quantity >= maxQuantityPerItem) {
      // [Cart.updateQuantity] would throw: at the limit, "+" does nothing.
      return;
    }
    emit(state.updateQuantity(productId, quantity + 1));
  }

  /// One fewer, but never below 1: taking the last one out is [remove]'s
  /// job (swipe or the delete button), so a tap on "−" can't empty a line
  /// by accident.
  void decrement(int productId) {
    final quantity = state.quantityOf(productId);
    if (quantity <= 1) {
      return; // not in the cart, or already at 1
    }
    emit(state.updateQuantity(productId, quantity - 1));
  }

  /// Empties the cart (after an order is placed, in Phase 8).
  void clear() {
    if (state.isEmpty) {
      return;
    }
    emit(const Cart.empty());
  }
}
