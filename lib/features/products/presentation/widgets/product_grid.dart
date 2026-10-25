import 'dart:math';

import 'package:flutter/material.dart';
import 'package:e_commerce_learn/app/theme/app_spacing.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_card.dart';

/// The grid gets one column for every this many dp of width...
const int _widthPerColumn = 200;

/// ...but never fewer than this many columns.
const int _minColumns = 2;

/// A grid of product cards whose number of columns follows the available
/// width.
///
/// The grid doesn't decide where a tap leads: the screen using it does,
/// through [onProductTap].
class ProductGrid extends StatelessWidget {
  const ProductGrid({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  final List<Product> products;
  final void Function(Product product) onProductTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // One column per 200 dp of width, but never fewer than 2.
        // The minimum also keeps the grid valid when Android lays
        // out the very first frame with a width of 0.
        final columns = max(
          _minColumns,
          constraints.maxWidth ~/ _widthPerColumn,
        );

        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.65,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];

            return ProductCard(
              product: product,
              onTap: () => onProductTap(product),
            );
          },
        );
      },
    );
  }
}
