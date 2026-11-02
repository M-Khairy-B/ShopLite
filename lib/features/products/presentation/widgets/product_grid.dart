import 'dart:math';

import 'package:flutter/material.dart';
import 'package:e_commerce_learn/app/theme/app_spacing.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_card.dart';

/// The grid gets one column for every this many dp of width...
const int _widthPerColumn = 200;

/// ...but never fewer than this many columns.
const int _minColumns = 2;

/// How close (in dp) to the end of the grid counts as "near the end": about
/// two rows of cards on a phone, so the next page is usually there before
/// the user reaches the bottom.
const double _nearEndDistance = 600;

/// A grid of product cards whose number of columns follows the available
/// width.
///
/// The grid doesn't decide where a tap leads, or how to get more products:
/// the screen using it does, through [onProductTap] and [onEndReached].
class ProductGrid extends StatefulWidget {
  const ProductGrid({
    super.key,
    required this.products,
    required this.onProductTap,
    this.onEndReached,
    this.footer,
  });

  final List<Product> products;
  final void Function(Product product) onProductTap;

  /// Called when the user scrolls near the end, and when the products don't
  /// fill the screen (then there is nothing to scroll). It is called often,
  /// so it must be safe to call while it is already loading. `null` means
  /// "don't ask for more".
  final void Function()? onEndReached;

  /// Shown below the last product, for example a "loading more" spinner.
  final Widget? footer;

  @override
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  // Owned by this State: created with it, disposed with it. (Not in the
  // cubit: scrolling is how this widget works, not what the app knows.)
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_reportIfNearEnd);
    _reportIfNearEndAfterLayout();
  }

  @override
  void didUpdateWidget(ProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only when the number of products changed: only then can the end have
    // moved. (Not when, say, just the footer changed.)
    if (widget.products.length != oldWidget.products.length) {
      _reportIfNearEndAfterLayout();
    }
  }

  @override
  void dispose() {
    // Also removes the listener. Without this, the controller would keep
    // listening after the grid is gone.
    _scrollController.dispose();
    super.dispose();
  }

  /// Checks once the new products are laid out: only then do we know whether
  /// they fill the screen.
  void _reportIfNearEndAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _reportIfNearEnd();
      }
    });
  }

  void _reportIfNearEnd() {
    final onEndReached = widget.onEndReached;
    if (onEndReached == null || !_scrollController.hasClients) {
      return;
    }
    // extentAfter: how much more there is to scroll below what's visible.
    if (_scrollController.position.extentAfter < _nearEndDistance) {
      onEndReached();
    }
  }

  /// Where the card with [key] is now, so Flutter can move that card
  /// (instead of building a new one) when the products change order.
  int? _indexOfCard(Key key) {
    if (key case ValueKey<int>(:final value)) {
      final index = widget.products.indexWhere((p) => p.id == value);
      return index == -1 ? null : index;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final footer = widget.footer;

    return LayoutBuilder(
      builder: (context, constraints) {
        // One column per 200 dp of width, but never fewer than 2.
        // The minimum also keeps the grid valid when Android lays
        // out the very first frame with a width of 0.
        final columns = max(
          _minColumns,
          constraints.maxWidth ~/ _widthPerColumn,
        );

        // A CustomScrollView scrolls several "slivers" as one list: here the
        // grid, then the footer below it.
        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.65,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = widget.products[index];

                    return ProductCard(
                      // Ties the card to its product, not to its position.
                      key: ValueKey(product.id),
                      product: product,
                      onTap: () => widget.onProductTap(product),
                    );
                  },
                  childCount: widget.products.length,
                  findChildIndexCallback: _indexOfCard,
                ),
              ),
            ),
            if (footer != null)
              // The footer is built even when it is far below the screen,
              // and a spinner that is built redraws every frame. So its
              // animations only run once it is close to being seen:
              // remainingCacheExtent is 0 until then.
              SliverLayoutBuilder(
                builder: (context, constraints) => SliverToBoxAdapter(
                  child: TickerMode(
                    enabled: constraints.remainingCacheExtent > 0,
                    child: footer,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
