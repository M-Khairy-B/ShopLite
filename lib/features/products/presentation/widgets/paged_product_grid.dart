import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_learn/app/theme/app_spacing.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/presentation/cubits/products_cubit.dart';
import 'package:e_commerce_learn/features/products/presentation/cubits/products_state.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_grid.dart';

/// The products of a [ProductsLoaded] state, as a grid that loads the next
/// page when the user nears its end (infinite scroll).
///
/// Below the products, a footer shows that more are loading, or why they
/// couldn't be loaded. Uses the [ProductsCubit] above it.
class PagedProductGrid extends StatelessWidget {
  const PagedProductGrid({
    super.key,
    required this.state,
    required this.onProductTap,
  });

  final ProductsLoaded state;
  final void Function(Product product) onProductTap;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductsCubit>();

    return ProductGrid(
      products: state.products,
      onProductTap: onProductTap,
      // Safe to call often: the cubit decides whether to load.
      onEndReached: cubit.loadMore,
      footer: _LoadMoreFooter(
        hasMore: state.hasMore,
        error: state.loadMoreError,
        onRetry: cubit.retryLoadMore,
      ),
    );
  }
}

/// What comes after the last product: why loading more failed, with
/// "Try again"; otherwise a spinner if there is more; otherwise nothing.
///
/// The spinner shows whenever there is more, not only while a page is on its
/// way. The user scrolling to the end then always finds it there; a footer
/// that appeared only once loading started would grow in below the screen,
/// where nobody sees it.
class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({
    required this.hasMore,
    required this.error,
    required this.onRetry,
  });

  final bool hasMore;
  final AppException? error;
  final void Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (error case final error?) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(
              "Couldn't load more products. ${error.message}",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (hasMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Loading more products',
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
