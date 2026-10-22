import 'package:flutter/material.dart';

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
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: categories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          // Index 0 is the "All" chip; the categories follow it.
          final category = index == 0 ? null : categories[index - 1];

          return ChoiceChip(
            label: Text(category == null ? 'All' : _capitalize(category)),
            selected: category == selectedCategory,
            onSelected: (_) => onSelected(category),
          );
        },
      ),
    );
  }

  String _capitalize(String text) => text[0].toUpperCase() + text.substring(1);
}
