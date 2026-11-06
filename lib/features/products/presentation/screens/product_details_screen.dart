import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/app/theme/app_spacing.dart';
import 'package:e_commerce_learn/app/theme/app_theme.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/core/utils/text_format.dart';
import 'package:e_commerce_learn/core/widgets/empty_view.dart';
import 'package:e_commerce_learn/core/widgets/error_view.dart';
import 'package:e_commerce_learn/core/widgets/loading_view.dart';
import 'package:e_commerce_learn/core/widgets/price_text.dart';
import 'package:e_commerce_learn/features/cart/data/models/cart.dart';
import 'package:e_commerce_learn/features/cart/presentation/add_to_cart.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';
import 'package:e_commerce_learn/features/products/presentation/cubits/product_details_cubit.dart';
import 'package:e_commerce_learn/features/products/presentation/cubits/product_details_state.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_image.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/quantity_selector.dart';
import 'package:e_commerce_learn/features/wishlist/presentation/widgets/wishlist_button.dart';

/// From this width (in dp) the image and the details sit side by side.
/// 600 dp is where Material Design stops treating a screen as "compact".
const double _wideLayoutBreakpoint = 600;

/// Shows everything we know about one product.
///
/// Opened at `/product/:id`. It receives only the product's id, and a
/// [ProductDetailsCubit] loads the product from the [ProductsRepository]
/// above it: a loading view first, then the product, a "not found" view, or
/// an error view with "Try again".
class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key, required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // A different product id means a different key, so Flutter replaces
      // this provider: the old cubit is closed and a new one loads the new
      // product. With the same key, `create` runs only once, however often
      // this screen rebuilds.
      key: ValueKey(productId),
      create: (context) => ProductDetailsCubit(
        repository: context.read<ProductsRepository>(),
        productId: productId,
      )..load(),
      // This screen's own messenger. Without it, snackbars go to the
      // outermost Scaffold (the tab shell's), just above the tabs, on top
      // of this screen's bottom bar. With it, "Added …" shows in this
      // Scaffold, above the bar, and goes away when the screen does.
      child: ScaffoldMessenger(
        child: Scaffold(
          appBar: AppBar(
            actions: [
              // Only once the product has loaded: saving needs its title,
              // photo and price.
              BlocBuilder<ProductDetailsCubit, ProductDetailsState>(
                builder: (context, state) {
                  if (state case ProductDetailsLoaded(:final product)) {
                    return WishlistButton(product: product);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          body: BlocBuilder<ProductDetailsCubit, ProductDetailsState>(
            builder: (context, state) {
              return switch (state) {
                ProductDetailsLoading() => const LoadingView(),
                ProductDetailsLoaded(:final product) => _ProductDetailsBody(
                  product: product,
                ),
                // Retrying won't make a missing product appear.
                ProductDetailsError(error: NotFoundException()) => EmptyView(
                  icon: Icons.inventory_2_outlined,
                  title: 'Product not found',
                  message: 'It may have been removed, or the link is wrong.',
                  action: FilledButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Back to home'),
                  ),
                ),
                ProductDetailsError(:final error) => ErrorView(
                  error: error,
                  onRetry: () => context.read<ProductDetailsCubit>().load(),
                ),
              };
            },
          ),
          // In the Scaffold's bottom slot, not in the scrolling content: it
          // stays in view while the description scrolls, and Flutter puts
          // snackbars above this slot, so "Added …" never covers the button.
          bottomNavigationBar:
              BlocBuilder<ProductDetailsCubit, ProductDetailsState>(
                builder: (context, state) {
                  if (state case ProductDetailsLoaded(:final product)) {
                    return _AddToCartBar(product: product);
                  }
                  return const SizedBox.shrink();
                },
              ),
        ),
      ),
    );
  }
}

/// The loaded product: image and info side by side on wide screens, stacked
/// on narrow ones.
class _ProductDetailsBody extends StatelessWidget {
  const _ProductDetailsBody({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final image = ProductImage(url: product.thumbnailUrl, fit: BoxFit.contain);

    return LayoutBuilder(
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
    );
  }
}

/// Title, price, rating and description, used by both layouts.
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
          // A heading: screen-reader users can jump between headings.
          Semantics(
            container: true,
            header: true,
            child: Text(product.title, style: textTheme.headlineSmall),
          ),
          const SizedBox(height: AppSpacing.sm),
          PriceText(
            product.priceCents,
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
                semanticsLabel: ratingSemanticsLabel(product.rating),
                style: textTheme.bodyLarge,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(product.description, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// The bar at the bottom of the screen: "− 1 +" and "Add to cart".
///
/// Stateful only to remember the quantity the selector last reported, for
/// "Add to cart". The selector still owns its count (Phase 1).
class _AddToCartBar extends StatefulWidget {
  const _AddToCartBar({required this.product});

  final Product product;

  @override
  State<_AddToCartBar> createState() => _AddToCartBarState();
}

class _AddToCartBarState extends State<_AddToCartBar> {
  var _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            QuantitySelector(
              maxQuantity: maxQuantityPerItem,
              // No setState: the number isn't shown here, only used when
              // "Add to cart" is tapped.
              onChanged: (quantity) => _quantity = quantity,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton.icon(
                onPressed: () =>
                    addToCart(context, widget.product, quantity: _quantity),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add to cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
