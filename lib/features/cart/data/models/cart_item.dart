import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:e_commerce_learn/core/utils/read_json.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';

part 'cart_item.g.dart';

/// One line of the cart: a product and how many of it.
///
/// It keeps a small copy (a "snapshot") of the product: only what the cart
/// screen shows. Not the whole [Product]: the description can be long, and
/// this is saved on the device.
///
/// Immutable: changing the quantity creates a new [CartItem].
@JsonSerializable(createToJson: true)
class CartItem extends Equatable {
  const CartItem({
    required this.productId,
    required this.title,
    required this.thumbnailUrl,
    required this.unitPriceCents,
    required this.quantity,
  });

  /// A new cart line for [product], with its price as it is now.
  factory CartItem.fromProduct(Product product, {int quantity = 1}) {
    return CartItem(
      productId: product.id,
      title: product.title,
      thumbnailUrl: product.thumbnailUrl,
      unitPriceCents: product.priceCents,
      quantity: quantity,
    );
  }

  /// Reads a cart line saved by [toJson]. Throws a [FormatException] if the
  /// saved data has the wrong shape.
  factory CartItem.fromJson(Map<String, dynamic> json) =>
      readJson(() => _$CartItemFromJson(json));

  Map<String, dynamic> toJson() => _$CartItemToJson(this);

  final int productId;
  final String title;
  final String thumbnailUrl;

  /// The price in cents when the product was added to the cart.
  ///
  /// For display only. If the price changes later, this line keeps the old
  /// one. A real shop must not trust it: the server prices the order from
  /// its own products table (Phase 9).
  final int unitPriceCents;

  final int quantity;

  /// [unitPriceCents] times [quantity]. Whole cents, so no rounding.
  int get lineTotalCents => unitPriceCents * quantity;

  /// A copy of this line with a different [quantity].
  CartItem withQuantity(int quantity) {
    return CartItem(
      productId: productId,
      title: title,
      thumbnailUrl: thumbnailUrl,
      unitPriceCents: unitPriceCents,
      quantity: quantity,
    );
  }

  @override
  List<Object?> get props => [
    productId,
    title,
    thumbnailUrl,
    unitPriceCents,
    quantity,
  ];
}
