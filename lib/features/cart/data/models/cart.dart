import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:e_commerce_learn/core/utils/read_json.dart';
import 'package:e_commerce_learn/features/cart/data/models/cart_item.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';

part 'cart.g.dart';

/// The shopping cart: a list of [CartItem]s, one per product, in the order
/// they were first added.
///
/// Immutable: every change ([add], [remove], [updateQuantity]) returns a
/// new [Cart] and leaves this one untouched. That is what lets a cubit emit
/// it: the old and new carts are different values, so the UI rebuilds.
@JsonSerializable(createToJson: true, explicitToJson: true)
class Cart extends Equatable {
  /// A cart with [items]. The list is copied, so changing the list you
  /// passed in later can't change the cart.
  Cart({required List<CartItem> items}) : items = List.unmodifiable(items);

  const Cart.empty() : items = const [];

  /// Reads a cart saved by [toJson]. Throws a [FormatException] if the saved
  /// data has the wrong shape.
  factory Cart.fromJson(Map<String, dynamic> json) =>
      readJson(() => _$CartFromJson(json));

  Map<String, dynamic> toJson() => _$CartToJson(this);

  /// Read-only: adding to it throws. Use [add] instead.
  final List<CartItem> items;

  bool get isEmpty => items.isEmpty;

  /// How many units are in the cart (2 mascaras + 1 palette = 3). This is
  /// the number on the cart badge.
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// The sum of every line's total, in cents.
  int get subtotalCents =>
      items.fold(0, (sum, item) => sum + item.lineTotalCents);

  /// How many of the product with [productId] are in the cart; 0 if none.
  int quantityOf(int productId) {
    for (final item in items) {
      if (item.productId == productId) return item.quantity;
    }
    return 0;
  }

  /// Adds [quantity] of [product]. If it's already in the cart, its quantity
  /// goes up, and the line keeps its place and its first price.
  ///
  /// Throws an [ArgumentError] if [quantity] is less than 1.
  Cart add(Product product, {int quantity = 1}) {
    _checkQuantity(quantity);
    final current = quantityOf(product.id);
    if (current == 0) {
      return Cart(
        items: [
          ...items,
          CartItem.fromProduct(product, quantity: quantity),
        ],
      );
    }
    return _withLine(
      product.id,
      (item) => item.withQuantity(current + quantity),
    );
  }

  /// Removes the product's line. A product that isn't in the cart is
  /// ignored.
  Cart remove(int productId) {
    return Cart(
      items: [
        for (final item in items)
          if (item.productId != productId) item,
      ],
    );
  }

  /// Sets the quantity of the product's line. A product that isn't in the
  /// cart is ignored. To take a product out, use [remove].
  ///
  /// Throws an [ArgumentError] if [quantity] is less than 1.
  Cart updateQuantity(int productId, int quantity) {
    _checkQuantity(quantity);
    return _withLine(productId, (item) => item.withQuantity(quantity));
  }

  /// A new cart where the line for [productId] is replaced by [change]'s
  /// result, in the same place. Every other line is the same object.
  Cart _withLine(int productId, CartItem Function(CartItem item) change) {
    return Cart(
      items: [
        for (final item in items)
          item.productId == productId ? change(item) : item,
      ],
    );
  }

  static void _checkQuantity(int quantity) {
    if (quantity < 1) {
      throw ArgumentError.value(quantity, 'quantity', 'must be at least 1');
    }
  }

  @override
  List<Object?> get props => [items];
}
