import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/app/theme/app_spacing.dart';
import 'package:e_commerce_learn/core/widgets/empty_view.dart';
import 'package:e_commerce_learn/core/widgets/error_view.dart';
import 'package:e_commerce_learn/core/widgets/loading_view.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/data/product_catalog.dart';
import 'package:e_commerce_learn/features/products/data/product_sort.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';
import 'package:e_commerce_learn/features/products/presentation/cubits/products_cubit.dart';
import 'package:e_commerce_learn/features/products/presentation/cubits/products_state.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/category_chips.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_grid.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/sort_options_sheet.dart';

/// The first screen of the app: category filters above a product grid.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// The catalog itself is loaded by a [ProductsCubit]. The user's choices
/// (category and sort) are UI state, so they stay here, and survive a retry.
class _HomeScreenState extends State<HomeScreen> {
  /// The selected category, or `null` when "All" is selected.
  String? _selectedCategory;

  /// The order the grid is shown in.
  ProductSort _sort = ProductSort.featured;

  /// Shows the "Sort by" sheet, applies the choice, and offers an Undo.
  Future<void> _chooseSort() async {
    final previous = _sort;

    // The sheet is a route on top of this screen. `await` waits until it
    // closes; the result is the tapped option, or null if dismissed.
    final chosen = await showModalBottomSheet<ProductSort>(
      context: context,
      // Open on the app's top-level navigator, above the bottom navigation
      // bar, so the sheet covers the whole app instead of only this tab.
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => SortOptionsSheet(selected: _sort),
    );

    // Nothing to do if the sheet was dismissed or the same sort was picked.
    // `mounted` guards against this screen having been removed while the
    // sheet was open; `context` must not be used after that.
    if (chosen == null || chosen == previous || !mounted) {
      return;
    }

    setState(() {
      _sort = chosen;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Showing: ${sortLabel(chosen)}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              if (mounted) {
                setState(() {
                  _sort = previous;
                });
              }
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // `create` runs once, not on every setState() of this screen.
      create: (context) =>
          ProductsCubit(repository: context.read<ProductsRepository>())..load(),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 32,
                height: 32,
                semanticLabel: 'ShopLite logo',
              ),
              const SizedBox(width: AppSpacing.md),
              const Text('ShopLite'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Sort products',
              icon: const Icon(Icons.sort),
              onPressed: _chooseSort,
            ),
          ],
        ),
        // BlocConsumer = a BlocBuilder (what to show) plus a BlocListener
        // (what to do once, like showing a snackbar) in one widget.
        body: BlocConsumer<ProductsCubit, ProductsState>(
          listener: (context, state) {
            // The products stay on screen; just say the refresh didn't work.
            if (state case ProductsLoaded(:final refreshError?)) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      "Couldn't refresh the catalog. ${refreshError.message}",
                    ),
                  ),
                );
            }
          },
          builder: (context, state) {
            return switch (state) {
              ProductsLoading() => const LoadingView(),
              ProductsLoaded(:final products) => _buildCatalog(
                products,
                // This builder's `context` is below the BlocProvider. The
                // State's own `context` is above it, so it couldn't find
                // the cubit.
                onRefresh: () => context.read<ProductsCubit>().refresh(),
              ),
              ProductsEmpty() => const EmptyView(
                icon: Icons.storefront_outlined,
                title: 'No products yet',
                message: 'New products will show up here.',
              ),
              ProductsError(:final error) => ErrorView(
                error: error,
                onRetry: () => context.read<ProductsCubit>().load(),
              ),
            };
          },
        ),
      ),
    );
  }

  /// The chips and the grid for the [loaded] products, filtered by the
  /// selected category and ordered by the selected sort. Pulling the grid
  /// down calls [onRefresh].
  Widget _buildCatalog(
    List<Product> loaded, {
    required Future<void> Function() onRefresh,
  }) {
    // A local copy, so Dart can tell it is non-null after the check below.
    final selectedCategory = _selectedCategory;
    final filtered = selectedCategory == null
        ? loaded
        : productsInCategory(loaded, selectedCategory);
    final products = sortProducts(filtered, _sort);

    return Column(
      // Full width for every child, so the chip row starts at the left
      // edge even when the chips don't fill the screen.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CategoryChips(
          categories: categoriesOf(loaded),
          selectedCategory: _selectedCategory,
          onSelected: (category) {
            setState(() {
              _selectedCategory = category;
            });
          },
        ),
        Expanded(
          // Shows its own spinner until the Future from onRefresh completes.
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ProductGrid(
              products: products,
              onProductTap: (product) => context.push('/product/${product.id}'),
            ),
          ),
        ),
      ],
    );
  }
}
