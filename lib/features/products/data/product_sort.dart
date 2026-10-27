import 'package:e_commerce_learn/features/products/data/models/product.dart';

/// The ways the catalog can be ordered.
enum ProductSort { featured, priceLowToHigh, priceHighToLow, topRated }

/// Returns a new list with [products] ordered by [sort].
///
/// The original list is never changed. That matters: loaded products live
/// in a state whose list can't be changed, so sorting in place would throw.
List<Product> sortProducts(List<Product> products, ProductSort sort) {
  final sorted = [...products];

  switch (sort) {
    case ProductSort.featured:
      break; // keep the catalog order
    case ProductSort.priceLowToHigh:
      sorted.sort((a, b) => a.priceCents.compareTo(b.priceCents));
    case ProductSort.priceHighToLow:
      sorted.sort((a, b) => b.priceCents.compareTo(a.priceCents));
    case ProductSort.topRated:
      sorted.sort((a, b) => b.rating.compareTo(a.rating));
  }

  return sorted;
}
