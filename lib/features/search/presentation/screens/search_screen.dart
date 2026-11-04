import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/app/theme/app_spacing.dart';
import 'package:e_commerce_learn/core/widgets/empty_view.dart';
import 'package:e_commerce_learn/core/widgets/error_view.dart';
import 'package:e_commerce_learn/core/widgets/loading_view.dart';
import 'package:e_commerce_learn/features/cart/presentation/add_to_cart.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_grid.dart';
import 'package:e_commerce_learn/features/search/presentation/cubits/search_cubit.dart';
import 'package:e_commerce_learn/features/search/presentation/cubits/search_state.dart';

/// Search the catalog: a search field in the app bar, results below.
///
/// This widget only provides the cubit; [_SearchView] below it builds the
/// screen, so every `context` it uses can find the cubit.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SearchCubit(repository: context.read<ProductsRepository>()),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  // What is typed in the field. Owned by this State (created with it,
  // disposed with it), like the grid's ScrollController: it belongs to the
  // widget, while the cubit only hears about the text through onChanged.
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    // clear() doesn't call onChanged (only typing does), so tell the cubit.
    context.read<SearchCubit>().queryChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchCubit>();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true, // the keyboard opens with the screen
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search products',
            border: InputBorder.none,
          ),
          onChanged: cubit.queryChanged,
          onSubmitted: cubit.submit,
        ),
        actions: [
          // A TextEditingController is a ValueNotifier (Phase 4): this part
          // rebuilds whenever the text changes, so the button shows only
          // while there is something to clear.
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.clear),
                    onPressed: _clear,
                  ),
          ),
        ],
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          return switch (state) {
            SearchIdle() => const EmptyView(
              icon: Icons.search,
              title: 'Search the catalog',
              message: 'Type a product name, like "phone".',
            ),
            SearchLoading() => const LoadingView(),
            SearchLoaded(:final products, :final total) => ProductGrid(
              products: products,
              onProductTap: (product) =>
                  context.push('/search/product/${product.id}'),
              onAddToCart: (product) => addToCart(context, product),
              footer: total > products.length
                  ? _MoreResultsNote(shown: products.length, total: total)
                  : null,
            ),
            SearchEmpty(:final query) => EmptyView(
              icon: Icons.search_off,
              title: 'No results',
              message: 'Nothing matches "$query". Try another word.',
            ),
            SearchError(:final error) => ErrorView(
              error: error,
              onRetry: cubit.retry,
            ),
          };
        },
      ),
    );
  }
}

/// Below the results, when more products match than one search shows.
class _MoreResultsNote extends StatelessWidget {
  const _MoreResultsNote({required this.shown, required this.total});

  final int shown;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(
        'Showing the first $shown of $total results. '
        'Type more to narrow them down.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
