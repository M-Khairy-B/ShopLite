import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_learn/features/cart/presentation/cubits/cart_cubit.dart';

/// Above this many items, the badge shows "9+": it's a small circle.
const _maxShownCount = 9;

/// The Cart tab's [icon], with a badge counting the items in the cart.
///
/// Its own widget so that a cart change rebuilds only this icon, not the
/// whole bottom bar: `context.select` makes *this* widget depend on the
/// cart's item count.
class CartTabIcon extends StatelessWidget {
  const CartTabIcon({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    // Rebuilds when the count changes, and only then.
    final count = context.select((CartCubit cart) => cart.state.itemCount);

    // A screen reader hears the exact number ("Cart, 12 items"), not the
    // badge's "9+".
    return Semantics(
      label: count == 0 ? null : '$count ${count == 1 ? 'item' : 'items'}',
      child: ExcludeSemantics(
        child: Badge(
          isLabelVisible: count > 0,
          label: Text(count > _maxShownCount ? '$_maxShownCount+' : '$count'),
          child: Icon(icon),
        ),
      ),
    );
  }
}
