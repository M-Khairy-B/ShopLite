import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/app/theme/app_spacing.dart';
import 'package:e_commerce_learn/app/theme/app_theme.dart';
import 'package:e_commerce_learn/core/utils/price_formatter.dart';
import 'package:e_commerce_learn/core/widgets/empty_view.dart';
import 'package:e_commerce_learn/features/products/data/mock_products.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_image.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/quantity_selector.dart';

/// From this width (in dp) the image and the details sit side by side.
/// 600 dp is where Material Design stops treating a screen as "compact".
const double _wideLayoutBreakpoint = 600;

/// Shows everything we know about one product.
///
/// Opened at `/product/:id`. It receives only the product's id and looks the
/// product up itself. On narrow screens the details scroll below the image;
/// on wide screens (tablets, landscape phones) they sit beside it.
class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key, required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context) {
    // Temporary: read from the mock list. In Phase 3 this becomes an API call.
    final product = findMockProductById(productId);
    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyView(
          icon: Icons.inventory_2_outlined,
          title: 'Product not found',
          message: 'It may have been removed, or the link is wrong.',
          action: FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Back to home'),
          ),
        ),
      );
    }

    final image = ProductImage(url: product.thumbnailUrl, fit: BoxFit.contain);

    return Scaffold(
      appBar: AppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= _wideLayoutBreakpoint) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: AspectRatio(aspectRatio: 1, child: image),
                  ),
                ),
                Expanded(
                  child: ListView(children: [_ProductInfo(product: product)]),
                ),
              ],
            );
          }

          return ListView(
            children: [
              AspectRatio(aspectRatio: 1, child: image),
              _ProductInfo(product: product),
            ],
          );
        },
      ),
    );
  }
}

/// Title, price, rating, quantity and description, used by both layouts.
class _ProductInfo extends StatelessWidget {
  const _ProductInfo({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.title, style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            formatPrice(product.priceCents),
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.star, color: ratingStarColor),
              const SizedBox(width: AppSpacing.xs),
              Text(
                product.rating.toStringAsFixed(1),
                style: textTheme.bodyLarge,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              // Expanded (not Spacer) lets the label shrink and wrap when
              // large text leaves too little room beside the selector.
              Expanded(child: Text('Quantity', style: textTheme.titleMedium)),
              const QuantitySelector(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(product.description, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}
