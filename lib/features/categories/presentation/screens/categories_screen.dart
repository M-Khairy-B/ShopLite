import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/core/widgets/empty_view.dart';
import 'package:e_commerce_learn/core/widgets/error_view.dart';
import 'package:e_commerce_learn/core/widgets/loading_view.dart';
import 'package:e_commerce_learn/features/categories/presentation/cubits/categories_cubit.dart';
import 'package:e_commerce_learn/features/categories/presentation/cubits/categories_state.dart';
import 'package:e_commerce_learn/features/products/data/products_repository.dart';

/// The Categories tab: every product category, loaded from the
/// [ProductsRepository].
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CategoriesCubit(repository: context.read<ProductsRepository>())
            ..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Categories')),
        body: BlocBuilder<CategoriesCubit, CategoriesState>(
          builder: (context, state) {
            return switch (state) {
              CategoriesLoading() => const LoadingView(),
              CategoriesLoaded(:final categories) => ListView(
                children: [
                  for (final category in categories)
                    ListTile(
                      leading: const Icon(Icons.category_outlined),
                      title: Text(category.name),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/categories/${category.slug}'),
                    ),
                ],
              ),
              CategoriesEmpty() => const EmptyView(
                icon: Icons.category_outlined,
                title: 'No categories yet',
                message: 'Categories will show up here.',
              ),
              CategoriesError(:final error) => ErrorView(
                error: error,
                onRetry: () => context.read<CategoriesCubit>().load(),
              ),
            };
          },
        ),
      ),
    );
  }
}
