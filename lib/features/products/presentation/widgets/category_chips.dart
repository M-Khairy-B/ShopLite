import 'package:flutter/material.dart';
import 'package:e_commerce_learn/core/utils/text_format.dart';

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

  final List<String> categories;

  /// The selected category, or `null` when "All" is selected.
  final String? selectedCategory;

  /// Called with the tapped category, or `null` when "All" is tapped.
  final void Function(String? category) onSelected;

  @override
  Widget build(BuildContext context) {
    // A scroll view + Row (instead of a fixed-height ListView) takes the
    // height of its tallest chip, so chips grow with the user's text size.
    // There are only a few categories, so building them all at once is fine.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        spacing: 8,
        children: [
          _buildChip(null),
          for (final category in categories) _buildChip(category),
        ],
      ),
    );
  }

  /// Builds one chip; a `null` category means the "All" chip.
  Widget _buildChip(String? category) {
    return ChoiceChip(
      label: Text(category == null ? 'All' : capitalize(category)),
      selected: category == selectedCategory,
      onSelected: (_) => onSelected(category),
    );
  }
}
