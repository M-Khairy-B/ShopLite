import 'package:flutter/material.dart';
import 'package:e_commerce_learn/app/theme/app_spacing.dart';
import 'package:e_commerce_learn/features/products/data/models/product_category.dart';

/// A horizontally scrolling row of category filters, with "All" first.
///
/// This widget holds no state of its own: the parent tells it which category
/// is selected, and is told through [onSelected] when the user taps a chip.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<ProductCategory> categories;

  /// The selected category's slug, or `null` when "All" is selected.
  final String? selectedCategory;

  /// Called with the tapped category's slug, or `null` when "All" is tapped.
  final void Function(String? category) onSelected;

  @override
  Widget build(BuildContext context) {
    // A scroll view + Row (instead of a fixed-height ListView) takes the
    // height of its tallest chip, so chips grow with the user's text size.
    // There are only a few categories, so building them all at once is fine.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          _buildChip(label: 'All', slug: null),
          for (final category in categories)
            _buildChip(label: category.name, slug: category.slug),
        ],
      ),
    );
  }

  /// Builds one chip; a `null` slug means the "All" chip.
  Widget _buildChip({required String label, required String? slug}) {
    return ChoiceChip(
      label: Text(label),
      selected: slug == selectedCategory,
      onSelected: (_) => onSelected(slug),
    );
  }
}
