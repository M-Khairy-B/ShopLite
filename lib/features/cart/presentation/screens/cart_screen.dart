import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/app/theme/app_spacing.dart';
import 'package:e_commerce_learn/core/widgets/empty_view.dart';
import 'package:e_commerce_learn/core/widgets/price_text.dart';
import 'package:e_commerce_learn/features/cart/data/models/cart.dart';
import 'package:e_commerce_learn/features/cart/data/models/cart_item.dart';
import 'package:e_commerce_learn/features/cart/presentation/cubits/cart_cubit.dart';
import 'package:e_commerce_learn/features/cart/presentation/widgets/cart_line_tile.dart';

/// The Cart tab: the lines in the cart, their totals, and the way to
/// checkout.
///
/// It doesn't provide a cubit: it uses the app's one `CartCubit` (see
/// `ShopLiteApp`), the same cart every other screen sees.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: BlocBuilder<CartCubit, Cart>(
        builder: (context, cart) {
          if (cart.isEmpty) {
            return EmptyView(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              message: 'Products you add to your cart will appear here.',
              action: FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Start shopping'),
              ),
            );
          }
          return Column(
            children: [
              Expanded(child: _CartLines(cart: cart)),
              _CartSummary(cart: cart),
            ],
          );
        },
      ),
    );
  }
}

class _CartLines extends StatelessWidget {
  const _CartLines({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CartCubit>();

    return ListView.separated(
      itemCount: cart.items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = cart.items[index];
        // The key is the product, not the position: after a removal, the
        // lines below move up, and each must stay matched to its product.
        // Dismissible requires a key that is unique in the list anyway.
        return Dismissible(
          key: ValueKey(item.productId),
          direction: DismissDirection.endToStart,
          background: const _DeleteBackground(),
          onDismissed: (_) => _removeWithUndo(context, index, item),
          child: CartLineTile(
            item: item,
            onIncrement: () => cubit.increment(item.productId),
            onDecrement: () => cubit.decrement(item.productId),
            onRemove: () => _removeWithUndo(context, index, item),
          ),
        );
      },
    );
  }

  /// Removes [item] and offers to put it back, at [index], as it was.
  void _removeWithUndo(BuildContext context, int index, CartItem item) {
    // Both are read now, while [context] is still in the tree: the row it
    // belongs to is about to go, and Undo is tapped later.
    final cubit = context.read<CartCubit>();
    final messenger = ScaffoldMessenger.of(context);

    // Removed right away: a dismissed Dismissible must leave the tree.
    cubit.remove(item.productId);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed ${item.title}'),
          // No isClosed check (unlike Home's sort Undo): this cubit lives as
          // long as the app, so it outlives any snackbar.
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => cubit.restore(index, item),
          ),
        ),
      );
  }
}

/// What shows behind a line while it's being swiped away.
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.errorContainer,
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.xl),
          child: Icon(
            Icons.delete_outline,
            color: colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}

/// The bottom of the cart: the subtotal and the checkout button.
class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final count = cart.itemCount;

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A Wrap, not a Row with Expanded: with large text on a narrow
            // phone, the price would squeeze the label to a letter per line.
            // A Wrap moves the price below the label instead.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.lg,
              children: [
                Text(
                  'Subtotal ($count ${count == 1 ? 'item' : 'items'})',
                  style: textTheme.titleMedium,
                ),
                // For display only: the order's real total is worked out
                // by the server from its own prices (Phase 9).
                PriceText(cart.subtotalCents, style: textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(content: Text('Checkout is coming soon.')),
                ),
              child: const Text('Proceed to checkout'),
            ),
          ],
        ),
      ),
    );
  }
}
