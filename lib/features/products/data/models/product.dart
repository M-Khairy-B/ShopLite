/// A single product in the store.
///
/// Immutable: every field is `final`, so a product never changes after it is
/// created. If product data changes, we create a new [Product].
class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.priceCents,
    required this.rating,
    required this.category,
    required this.thumbnailUrl,
  });

  final int id;
  final String title;
  final String description;

  /// Price in cents (e.g. 1299 = $12.99). Stored as an `int` because
  /// `double` cannot represent most decimal amounts exactly.
  final int priceCents;

  /// Average customer rating from 0 to 5.
  final double rating;

  final String category;
  final String thumbnailUrl;
}
