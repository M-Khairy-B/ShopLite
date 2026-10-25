import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/app/theme/app_spacing.dart';
import 'package:e_commerce_learn/app/theme/app_theme.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/core/utils/price_formatter.dart';
import 'package:e_commerce_learn/core/utils/text_format.dart';
import 'package:e_commerce_learn/core/widgets/empty_view.dart';
import 'package:e_commerce_learn/core/widgets/error_view.dart';
import 'package:e_commerce_learn/core/widgets/loading_view.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_image.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/quantity_selector.dart';

/// From this width (in dp) the image and the details sit side by side.
/// 600 dp is where Material Design stops treating a screen as "compact".
const double _wideLayoutBreakpoint = 600;

/// Shows everything we know about one product.
///
/// Opened at `/product/:id`. It receives only the product's id and loads the
/// product from [repository]: a loading view first, then the product, a
/// "not found" view, or an error view with "Try again".
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.productId,
    required this.repository,
  });

  final int productId;
  final ProductsRepository repository;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  /// The request for the product. Started once in [initState], not in
  /// build(): build() can run many times, and each run would send the
  /// request again.
  late Future<Product> _product;

  @override
  void initState() {
    super.initState();
    _product = widget.repository.getProduct(widget.productId);
  }

  @override
  void didUpdateWidget(covariant ProductDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Same screen, different product (e.g. a new id in the route): load it.
    if (oldWidget.productId != widget.productId) {
      _product = widget.repository.getProduct(widget.productId);
    }
  }

  void _retry() {
    setState(() {
      _product = widget.repository.getProduct(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<Product>(
        future: _product,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }

          final error = snapshot.error;
          if (error != null) {
            return switch (error) {
              NotFoundException() => EmptyView(
                icon: Icons.inventory_2_outlined,
                title: 'Product not found',
                message: 'It may have been removed, or the link is wrong.',
                action: FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Back to home'),
                ),
              ),
              final AppException error => ErrorView(
                error: error,
                onRetry: _retry,
              ),
              // The repository promises AppExceptions only; anything else
              // is a bug, but the user still gets a way to retry.
              _ => ErrorView(error: const UnknownException(), onRetry: _retry),
            };
          }

          return _ProductDetailsBody(product: snapshot.requireData);
        },
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
          // A heading: screen-reader users can jump between headings.
          Semantics(
            container: true,
            header: true,
            child: Text(product.title, style: textTheme.headlineSmall),
          ),
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
                semanticsLabel: ratingSemanticsLabel(product.rating),
                style: textTheme.bodyLarge,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              // Expanded (not Spacer) lets the label shrink and wrap when
              // large text leaves too little room beside the selector.
              // Hidden from screen readers: the selector itself announces
              // "Quantity", so reading this label too would say it twice.
              Expanded(
                child: ExcludeSemantics(
                  child: Text('Quantity', style: textTheme.titleMedium),
                ),
              ),
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
