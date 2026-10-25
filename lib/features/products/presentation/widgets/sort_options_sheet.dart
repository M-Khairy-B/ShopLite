import 'package:flutter/material.dart';
import 'package:e_commerce_learn/app/theme/app_spacing.dart';
import 'package:e_commerce_learn/features/products/data/product_sort.dart';

/// The text shown to the user for each [ProductSort].
String sortLabel(ProductSort sort) {
  return switch (sort) {
    ProductSort.featured => 'Featured',
    ProductSort.priceLowToHigh => 'Price: low to high',
    ProductSort.priceHighToLow => 'Price: high to low',
    ProductSort.topRated => 'Top rated',
  };
}

/// The content of the "Sort by" bottom sheet.
///
/// Tapping an option closes the sheet and returns that option to whoever
/// opened it (see `showModalBottomSheet` in `HomeScreen`).
class SortOptionsSheet extends StatelessWidget {
  const SortOptionsSheet({super.key, required this.selected});

  /// The sort in use right now; it is shown as selected.
  final ProductSort selected;

  @override
  Widget build(BuildContext context) {
    // A ListView (not a Column) so the options scroll instead of overflowing
    // when large text meets a short landscape screen.
    return ListView(
      shrinkWrap: true,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'Sort by',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (final sort in ProductSort.values)
          ListTile(
            title: Text(sortLabel(sort)),
            selected: sort == selected,
            trailing: sort == selected ? const Icon(Icons.check) : null,
            onTap: () => Navigator.of(context).pop(sort),
          ),
      ],
    );
  }
}
