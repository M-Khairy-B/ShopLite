import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/cart/data/models/cart.dart';
import 'package:e_commerce_learn/features/cart/data/models/cart_item.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';

import '../../../../helpers/mock_products.dart';

void main() {
  final mascara = mockProducts[0]; // id 1, $9.99
  final palette = mockProducts[1]; // id 2, $19.99
  final perfume = mockProducts[2]; // id 6, $49.99

  /// The products in [cart], in order, as (id, quantity) pairs.
  List<(int, int)> lines(Cart cart) {
    return [for (final item in cart.items) (item.productId, item.quantity)];
  }

  group('an empty cart', () {
    test('has no items, no units and a zero subtotal', () {
      const cart = Cart.empty();

      expect(cart.isEmpty, isTrue);
      expect(cart.itemCount, 0);
      expect(cart.subtotalCents, 0);
      expect(cart.quantityOf(1), 0);
    });

    test('is equal to a cart made from an empty list', () {
      expect(Cart(items: const []), const Cart.empty());
    });
  });

  group('add', () {
    test('a new product becomes a new line at the end', () {
      final cart = const Cart.empty().add(mascara).add(palette);

      expect(lines(cart), [(1, 1), (2, 1)]);
      expect(cart.isEmpty, isFalse);
    });

    test('a product already in the cart raises its quantity, in place', () {
      final cart = const Cart.empty()
          .add(mascara)
          .add(palette)
          .add(mascara, quantity: 2);

      expect(lines(cart), [(1, 3), (2, 1)]);
    });

    test('adding again keeps the price from the first time', () {
      final cart = const Cart.empty().add(mascara);
      final cheaper = Product(
        id: mascara.id,
        title: mascara.title,
        description: mascara.description,
        priceCents: 499,
        rating: mascara.rating,
        category: mascara.category,
        thumbnailUrl: mascara.thumbnailUrl,
      );

      final updated = cart.add(cheaper);

      expect(updated.items.single.unitPriceCents, 999);
      expect(updated.items.single.quantity, 2);
    });

    test('a quantity below 1 is an ArgumentError', () {
      expect(
        () => const Cart.empty().add(mascara, quantity: 0),
        throwsArgumentError,
      );
    });
  });

  group('remove', () {
    test('takes out the whole line, whatever its quantity', () {
      final cart = const Cart.empty()
          .add(mascara, quantity: 3)
          .add(palette)
          .remove(1);

      expect(lines(cart), [(2, 1)]);
    });

    test('a product that is not in the cart changes nothing', () {
      final cart = const Cart.empty().add(mascara);

      expect(cart.remove(99), cart);
    });
  });

  group('updateQuantity', () {
    test('sets the quantity of that line only', () {
      final cart = const Cart.empty()
          .add(mascara)
          .add(palette)
          .updateQuantity(2, 5);

      expect(lines(cart), [(1, 1), (2, 5)]);
    });

    test('a product that is not in the cart changes nothing', () {
      final cart = const Cart.empty().add(mascara);

      expect(cart.updateQuantity(99, 5), cart);
    });

    test('a quantity below 1 is an ArgumentError (use remove instead)', () {
      final cart = const Cart.empty().add(mascara);

      expect(() => cart.updateQuantity(1, 0), throwsArgumentError);
    });
  });

  group('totals', () {
    test('itemCount counts units, not lines', () {
      final cart = const Cart.empty().add(mascara, quantity: 2).add(palette);

      expect(cart.itemCount, 3);
      expect(cart.items, hasLength(2));
    });

    test('the subtotal adds whole cents exactly', () {
      // 3 × $9.99 + $19.99 + $49.99. Added as doubles, these come to
      // 99.94999999999999.
      final cart = const Cart.empty()
          .add(mascara, quantity: 3)
          .add(palette)
          .add(perfume);

      expect(cart.subtotalCents, 2997 + 1999 + 4999);
      expect(cart.subtotalCents, 9995);
    });

    test('quantityOf finds the line for that product', () {
      final cart = const Cart.empty().add(mascara).add(palette, quantity: 4);

      expect(cart.quantityOf(2), 4);
      expect(cart.quantityOf(6), 0);
    });
  });

  group('immutability', () {
    test('every change leaves the old cart as it was', () {
      final before = const Cart.empty().add(mascara);

      before.add(palette);
      before.updateQuantity(1, 7);
      before.remove(1);

      expect(lines(before), [(1, 1)]);
    });

    test('the items list cannot be changed from outside', () {
      final cart = const Cart.empty().add(mascara);

      expect(
        () => cart.items.add(CartItem.fromProduct(palette)),
        throwsUnsupportedError,
      );
    });

    test('changing the list passed in later does not change the cart', () {
      final list = [CartItem.fromProduct(mascara)];
      final cart = Cart(items: list);

      list.add(CartItem.fromProduct(palette));

      expect(lines(cart), [(1, 1)]);
    });

    test('two carts with the same lines are equal', () {
      expect(
        const Cart.empty().add(mascara).add(palette),
        const Cart.empty().add(mascara).add(palette),
      );
    });
  });

  group('JSON', () {
    test('fromJson reads back what toJson wrote', () {
      final cart = const Cart.empty().add(mascara, quantity: 2).add(palette);

      expect(Cart.fromJson(cart.toJson()), cart);
    });

    test('toJson writes each line as a plain map', () {
      final json = const Cart.empty().add(mascara).toJson();

      expect(json['items'], [CartItem.fromProduct(mascara).toJson()]);
    });

    test('a broken line is a FormatException that names the path to it', () {
      final json = {
        'items': [
          {'productId': 1, 'title': 'Mascara'},
        ],
      };

      expect(
        () => Cart.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('Could not read Cart: there is a problem with "items"'),
              contains('CartItem'),
            ),
          ),
        ),
      );
    });
  });
}
