import 'package:equatable/equatable.dart';

/// A product category, as listed by DummyJSON's `/products/categories`.
///
/// Called `ProductCategory`, not `Category`: Flutter already has a `Category`
/// class (exported by `material.dart`), and the two names would clash.
class ProductCategory extends Equatable {
  const ProductCategory({required this.slug, required this.name});

  /// Reads one category from the API's JSON (its `url` field isn't needed).
  /// Throws a [FormatException] if the shape is wrong.
  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'slug': final String slug, 'name': final String name} => ProductCategory(
        slug: slug,
        name: name,
      ),
      _ => throw FormatException('Not a valid category: $json'),
    };
  }

  /// Reads the whole list the API returns. Throws a [FormatException] if any
  /// item is not a valid category object.
  static List<ProductCategory> listFromJson(List<dynamic> json) {
    return [
      for (final item in json)
        switch (item) {
          final Map<String, dynamic> category => ProductCategory.fromJson(
            category,
          ),
          _ => throw FormatException('Not a category object: $item'),
        },
    ];
  }

  /// The id used in URLs and in `Product.category`, e.g. `home-decoration`.
  final String slug;

  /// The name to show, e.g. `Home Decoration`.
  final String name;

  @override
  List<Object?> get props => [slug, name];
}
