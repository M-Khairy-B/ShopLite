import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/app/theme/app_spacing.dart';
import 'package:e_commerce_learn/core/widgets/empty_view.dart';
import 'package:e_commerce_learn/core/widgets/error_view.dart';
import 'package:e_commerce_learn/core/widgets/loading_view.dart';
import 'package:e_commerce_learn/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:e_commerce_learn/features/categories/presentation/cubits/categories_state.dart';
import 'package:e_commerce_learn/features/products/data/product_sort.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';
import 'package:e_commerce_learn/features/products/presentation/cubits/products_cubit.dart';
import 'package:e_commerce_learn/features/products/presentation/cubits/products_state.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/category_chips.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/paged_product_grid.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/sort_options_sheet.dart';

/// The first screen of the app: category filters above a product grid.
///
/// This widget only provides the two cubits; [_HomeView] below them builds
/// the screen, so every `context` it uses can find them.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<ProductsRepository>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ProductsCubit(repository: repository)..load(),
        ),
        BlocProvider(
          create: (context) => CategoriesCubit(repository: repository)..load(),
        ),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            onPressed: () => _chooseSort(context),
          ),
        ],
      ),
      body: const Column(
        // Full width for every child, so the chip row starts at the left
        // edge even when the chips don't fill the screen.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Outside the catalog's loading/error switch, so the chips stay
          // while another category loads.
          _CategoryFilter(),
          Expanded(child: _Catalog()),
        ],
      ),
    );
  }

  /// Shows the "Sort by" sheet, applies the choice, and offers an Undo.
  Future<void> _chooseSort(BuildContext context) async {
    final cubit = context.read<ProductsCubit>();
    final previous = cubit.state.query.sort;

    // The sheet is a route on top of this screen. `await` waits until it
    // closes; the result is the tapped option, or null if dismissed.
    final chosen = await showModalBottomSheet<ProductSort>(
      context: context,
      // Open on the app's top-level navigator, above the bottom navigation
      // bar, so the sheet covers the whole app instead of only this tab.
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => SortOptionsSheet(selected: previous),
    );

    // Nothing to do if the sheet was dismissed or the same sort was picked.
    // `context.mounted` guards against this screen having been removed
    // while the sheet was open; `context` must not be used after that.
    if (chosen == null || chosen == previous || !context.mounted) {
      return;
    }

    // Not awaited on purpose: the snackbar appears now, while the new order
    // loads.
    unawaited(cubit.changeSort(chosen));

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Showing: ${sortLabel(chosen)}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // The snackbar can outlive this screen; a closed cubit can't
              // emit.
              if (!cubit.isClosed) {
                cubit.changeSort(previous);
              }
            },
          ),
        ),
      );
  }
}

/// The category chips. They are a shortcut, not the content: while the
/// categories load, or if they fail, there are simply no chips.
class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter();

  @override
  Widget build(BuildContext context) {
    // Rebuild when the selected category changes, and only then: not on
    // every catalog state (loading, loaded, ...).
    final selected = context.select(
      (ProductsCubit cubit) => cubit.state.query.category,
    );

    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        return switch (state) {
          CategoriesLoaded(:final categories) => CategoryChips(
            categories: categories,
            selectedCategory: selected,
            onSelected: (category) =>
                context.read<ProductsCubit>().selectCategory(category),
          ),
          CategoriesLoading() ||
          CategoriesEmpty() ||
          CategoriesError() => const SizedBox.shrink(),
        };
      },
    );
  }
}

/// The product grid, with its loading, empty and error states.
class _Catalog extends StatelessWidget {
  const _Catalog();

  @override
  Widget build(BuildContext context) {
    // BlocConsumer = a BlocBuilder (what to show) plus a BlocListener
    // (what to do once, like showing a snackbar) in one widget.
    return BlocConsumer<ProductsCubit, ProductsState>(
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
          // Shows its own spinner until the Future from onRefresh completes.
          ProductsLoaded() => RefreshIndicator(
            onRefresh: () => context.read<ProductsCubit>().refresh(),
            child: PagedProductGrid(
              state: state,
              onProductTap: (product) => context.push('/product/${product.id}'),
            ),
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
    );
  }
}
