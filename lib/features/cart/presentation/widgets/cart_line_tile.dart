import 'package:flutter/material.dart';
import 'package:e_commerce_learn/app/theme/app_spacing.dart';
import 'package:e_commerce_learn/core/utils/price_formatter.dart';
import 'package:e_commerce_learn/core/widgets/price_text.dart';
import 'package:e_commerce_learn/features/cart/data/models/cart.dart';
import 'package:e_commerce_learn/features/cart/data/models/cart_item.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_image.dart';

/// One line of the cart screen: photo, title, unit price, "− 2 +", the line
/// total, and a delete button.
///
/// It only shows [item] and reports taps: the cart itself changes in
/// `CartCubit`, so this widget has no state of its own.
class CartLineTile extends StatelessWidget {
  const CartLineTile({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            child: SizedBox.square(
              dimension: 64,
              child: ProductImage(url: item.thumbnailUrl),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${formatPrice(item.unitPriceCents)} each',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // A Wrap, not a Row: with large text the total moves below
                // the buttons instead of overflowing.
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _QuantityButtons(
                      title: item.title,
                      quantity: item.quantity,
                      onIncrement: onIncrement,
                      onDecrement: onDecrement,
                    ),
                    PriceText(
                      item.lineTotalCents,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove from cart',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

/// "− 2 +" for a cart line. Like `QuantitySelector` on the details screen,
/// but the number comes from the cart instead of the widget's own state.
class _QuantityButtons extends StatelessWidget {
  const _QuantityButtons({
    required this.title,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String title;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    // One group for screen readers: "Quantity of <title>, 2", then the two
    // buttons inside it. Disabled buttons say why nothing happens: "−" at 1
    // (deleting is the delete button's job) and "+" at the limit.
    return Semantics(
      container: true,
      label: 'Quantity of $title',
      value: '$quantity',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.outlined(
            tooltip: 'Decrease quantity',
            onPressed: quantity > 1 ? onDecrement : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 40,
            child: ExcludeSemantics(
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          IconButton.outlined(
            tooltip: 'Increase quantity',
            onPressed: quantity < maxQuantityPerItem ? onIncrement : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
