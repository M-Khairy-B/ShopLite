import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:e_commerce_learn/core/utils/read_json.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';

part 'wishlist_item.g.dart';

/// One saved product in the wishlist.
///
/// Like a cart line, it keeps a small copy (a "snapshot") of the product:
/// what the wishlist screen shows, so the screen needs no network. Not the
/// whole [Product]: this is saved on the device (Task 6).
@JsonSerializable(createToJson: true)
class WishlistItem extends Equatable {
  const WishlistItem({
    required this.productId,
    required this.title,
    required this.thumbnailUrl,
    required this.priceCents,
  });

  /// A wishlist entry for [product], with its price as it is now.
  factory WishlistItem.fromProduct(Product product) {
    return WishlistItem(
      productId: product.id,
      title: product.title,
      thumbnailUrl: product.thumbnailUrl,
      priceCents: product.priceCents,
    );
  }

  /// Reads an entry saved by [toJson]. Throws a [FormatException] if the
  /// saved data has the wrong shape.
  factory WishlistItem.fromJson(Map<String, dynamic> json) =>
      readJson(() => _$WishlistItemFromJson(json));

  Map<String, dynamic> toJson() => _$WishlistItemToJson(this);

  final int productId;
  final String title;
  final String thumbnailUrl;

  /// The price in cents when the product was saved. It may be out of date:
  /// the details screen loads the product, with its price now.
  final int priceCents;

  @override
  List<Object?> get props => [productId, title, thumbnailUrl, priceCents];
}
