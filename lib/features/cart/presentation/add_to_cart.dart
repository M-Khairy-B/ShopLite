import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/features/cart/data/models/cart.dart';
import 'package:e_commerce_learn/features/cart/presentation/cubits/cart_cubit.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';

/// Adds [quantity] of [product] to the cart, and says so in a snackbar with
/// a "View cart" action.
///
/// Used by every "Add to cart" button (cards and the details screen), so
/// they all behave and speak the same way.
void addToCart(BuildContext context, Product product, {int quantity = 1}) {
  // All three are read now, while [context] is surely in the tree: "View
  // cart" is tapped later, maybe after this card has scrolled away.
  final cart = context.read<CartCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);

  final added = cart.add(product, quantity: quantity);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(_message(product.title, quantity, added)),
        action: SnackBarAction(
          label: 'View cart',
          onPressed: () => router.go('/cart'),
        ),
      ),
    );
}

/// What happened when [requested] of [title] were asked for and [added]
/// really went in: all of them, some (the limit was reached), or none.
String _message(String title, int requested, int added) {
  if (added == 0) {
    return 'Your cart already has $maxQuantityPerItem × $title, '
        'the limit per product.';
  }
  if (added < requested) {
    return 'Added $added × $title. '
        'You now have $maxQuantityPerItem, the limit per product.';
  }
  return 'Added $added × $title';
}
