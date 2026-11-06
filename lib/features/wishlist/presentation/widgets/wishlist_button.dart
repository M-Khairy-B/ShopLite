import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/wishlist/presentation/cubits/wishlist_cubit.dart';

/// A heart that saves [product] to the wishlist, or removes it if it's
/// saved. On product cards and in the details screen's app bar.
///
/// Its own widget so that a change rebuilds only the hearts it changes:
/// `context.select` makes *this* widget depend on "is this product saved?",
/// not on the whole wishlist. Saving one product rebuilds one heart, not
/// every card on the screen.
class WishlistButton extends StatelessWidget {
  const WishlistButton({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final saved = context.select(
      (WishlistCubit wishlist) => wishlist.state.contains(product.id),
    );

    // A toggle button: with `isSelected`, a screen reader hears "selected"
    // or "not selected" along with the tooltip.
    return IconButton(
      isSelected: saved,
      tooltip: saved ? 'Remove from wishlist' : 'Add to wishlist',
      onPressed: () => context.read<WishlistCubit>().toggle(product),
      icon: const Icon(Icons.favorite_border),
      // Its own color: an AppBar gives its buttons one color for every
      // state, which would make a saved heart grey there.
      selectedIcon: Icon(
        Icons.favorite,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
