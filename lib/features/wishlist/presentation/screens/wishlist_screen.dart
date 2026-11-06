import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/app/theme/app_spacing.dart';
import 'package:e_commerce_learn/core/widgets/empty_view.dart';
import 'package:e_commerce_learn/core/widgets/price_text.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_image.dart';
import 'package:e_commerce_learn/features/wishlist/data/models/wishlist.dart';
import 'package:e_commerce_learn/features/wishlist/data/models/wishlist_item.dart';
import 'package:e_commerce_learn/features/wishlist/presentation/cubits/wishlist_cubit.dart';

/// The products the user saved for later, newest first. Opened from the
/// Profile tab, at `/profile/wishlist`.
///
/// It shows the saved snapshots, so it needs no network. A tap opens the
/// product, which loads it as it is now (its price may have changed).
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: BlocBuilder<WishlistCubit, Wishlist>(
        builder: (context, wishlist) {
          if (wishlist.isEmpty) {
            return EmptyView(
              icon: Icons.favorite_border,
              title: 'Your wishlist is empty',
              message: 'Tap the heart on a product to save it here.',
              action: FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Start shopping'),
              ),
            );
          }
          return ListView.separated(
            itemCount: wishlist.items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = wishlist.items[index];
              return _WishlistTile(
                // The product, not the position, as in the cart.
                key: ValueKey(item.productId),
                item: item,
              );
            },
          );
        },
      ),
    );
  }
}

/// One saved product: photo, title, price, and a heart that removes it.
class _WishlistTile extends StatelessWidget {
  const _WishlistTile({super.key, required this.item});

  final WishlistItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: SizedBox.square(
          dimension: 56,
          child: ProductImage(url: item.thumbnailUrl),
        ),
      ),
      title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      // The price when it was saved: the details screen shows today's.
      subtitle: PriceText(item.priceCents),
      // Inside the Profile tab, so back returns here.
      onTap: () => context.push('/profile/wishlist/product/${item.productId}'),
      // No Undo: a heart on the product puts it back with one tap.
      // Selected, like a saved product's heart on a card: a screen reader
      // hears the same "selected". The color is set on the icon, because a
      // ListTile gives its buttons one color for every state.
      trailing: IconButton(
        isSelected: true,
        tooltip: 'Remove from wishlist',
        onPressed: () => context.read<WishlistCubit>().remove(item.productId),
        icon: Icon(
          Icons.favorite,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
