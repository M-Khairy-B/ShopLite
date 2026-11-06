import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:e_commerce_learn/core/utils/read_json.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/wishlist/data/models/wishlist_item.dart';

part 'wishlist.g.dart';

/// The products the user saved for later: one [WishlistItem] per product,
/// newest first.
///
/// Immutable, like `Cart`: [toggle] and [remove] return a new wishlist and
/// leave this one untouched.
@JsonSerializable(createToJson: true, explicitToJson: true)
class Wishlist extends Equatable {
  /// A wishlist with [items]. The list is copied, so changing the list you
  /// passed in later can't change the wishlist.
  Wishlist({required List<WishlistItem> items})
    : items = List.unmodifiable(items);

  const Wishlist.empty() : items = const [];

  /// Reads a wishlist saved by [toJson]. Throws a [FormatException] if the
  /// saved data has the wrong shape.
  factory Wishlist.fromJson(Map<String, dynamic> json) =>
      readJson(() => _$WishlistFromJson(json));

  Map<String, dynamic> toJson() => _$WishlistToJson(this);

  /// Read-only, newest first.
  final List<WishlistItem> items;

  bool get isEmpty => items.isEmpty;

  /// Whether the product with [productId] is saved.
  bool contains(int productId) {
    return items.any((item) => item.productId == productId);
  }

  /// Saves [product] (at the top) if it isn't saved, and removes it if it
  /// is: what a tap on a heart does.
  Wishlist toggle(Product product) {
    if (contains(product.id)) {
      return remove(product.id);
    }
    return Wishlist(items: [WishlistItem.fromProduct(product), ...items]);
  }

  /// Removes the product with [productId]. A product that isn't saved is
  /// ignored.
  Wishlist remove(int productId) {
    return Wishlist(
      items: [
        for (final item in items)
          if (item.productId != productId) item,
      ],
    );
  }

  @override
  List<Object?> get props => [items];
}
