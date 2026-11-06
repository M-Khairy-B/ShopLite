import 'package:flutter/material.dart';
import 'package:e_commerce_learn/app/theme/app_spacing.dart';
import 'package:e_commerce_learn/app/theme/app_theme.dart';
import 'package:e_commerce_learn/core/utils/price_formatter.dart';
import 'package:e_commerce_learn/core/utils/text_format.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_image.dart';

/// A compact card showing a product's image, title, price and rating.
///
/// The image fills whatever height is left after the text, so the card
/// adapts to the size its parent gives it (for example, a grid cell).
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.wishlistButton,
  });

  final Product product;

  /// Called when the card is tapped. If `null`, the card is not tappable.
  final void Function()? onTap;

  /// Called by the card's "Add to cart" button. If `null`, there is no
  /// button.
  final void Function()? onAddToCart;

  /// Shown over the image's top corner. If `null`, there is none.
  ///
  /// A widget, not a callback like [onAddToCart]: the heart reads the
  /// wishlist itself, so a change rebuilds the heart and not the card.
  final Widget? wishlistButton;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final onAddToCart = this.onAddToCart;
    final wishlistButton = this.wishlistButton;

    return Card(
      clipBehavior: Clip.antiAlias,
      // Tells screen readers this card is a button ("double-tap to open").
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductImage(url: product.thumbnailUrl),
                    if (wishlistButton != null)
                      PositionedDirectional(
                        top: AppSpacing.xs,
                        end: AppSpacing.xs,
                        // A disc behind the heart, so it shows on any
                        // photo, light or dark.
                        child: Material(
                          color: colorScheme.surface,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: wishlistButton,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatPrice(product.priceCents),
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Its own button inside the card: a tap here adds
                        // to the cart, a tap anywhere else opens the
                        // product.
                        if (onAddToCart != null)
                          IconButton(
                            tooltip: 'Add to cart',
                            onPressed: onAddToCart,
                            icon: const Icon(Icons.add_shopping_cart),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: ratingStarColor,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          product.rating.toStringAsFixed(1),
                          semanticsLabel: ratingSemanticsLabel(product.rating),
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
