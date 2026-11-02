import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/core/utils/text_format.dart';
import 'package:e_commerce_learn/core/widgets/empty_view.dart';
import 'package:e_commerce_learn/core/widgets/error_view.dart';
import 'package:e_commerce_learn/core/widgets/loading_view.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';
import 'package:e_commerce_learn/features/products/presentation/cubits/products_cubit.dart';
import 'package:e_commerce_learn/features/products/presentation/cubits/products_state.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/paged_product_grid.dart';

/// Shows the products of one category. Opened at `/categories/:category`,
/// where `category` is the category's slug.
///
/// The same [ProductsCubit] as Home, asked for one category only.
class CategoryProductsScreen extends StatelessWidget {
  const CategoryProductsScreen({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Like the details screen: another category means another cubit.
      key: ValueKey(category),
      create: (context) => ProductsCubit(
        repository: context.read<ProductsRepository>(),
        category: category,
      )..load(),
      child: Scaffold(
        appBar: AppBar(title: Text(titleFromSlug(category))),
        body: BlocBuilder<ProductsCubit, ProductsState>(
          builder: (context, state) {
            return switch (state) {
              ProductsLoading() => const LoadingView(),
              ProductsLoaded() => PagedProductGrid(
                state: state,
                // Stay inside the Categories tab: this product page is
                // nested under the category, not under Home.
                onProductTap: (product) =>
                    context.push('/categories/$category/product/${product.id}'),
              ),
              ProductsEmpty() => EmptyView(
                icon: Icons.category_outlined,
                title: 'No products here',
                message: 'There are no products in this category yet.',
                action: FilledButton(
                  onPressed: () => context.go('/categories'),
                  child: const Text('See all categories'),
                ),
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
}
