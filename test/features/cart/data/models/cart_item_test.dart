import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/cart/data/models/cart_item.dart';

import '../../../../helpers/mock_products.dart';

void main() {
  final mascara = mockProducts[0]; // id 1, $9.99

  test(
    'fromProduct copies what the cart shows, with the price as it is now',
    () {
      final item = CartItem.fromProduct(mascara);

      expect(item.productId, 1);
      expect(item.title, 'Essence Mascara Lash Princess');
      expect(item.thumbnailUrl, mascara.thumbnailUrl);
      expect(item.unitPriceCents, 999);
      expect(item.quantity, 1);
    },
  );

  test('fromProduct can start with more than one', () {
    expect(CartItem.fromProduct(mascara, quantity: 3).quantity, 3);
  });

  test('the line total is the unit price times the quantity, in cents', () {
    final palette = mockProducts[1]; // id 2, $19.99

    // 5 × $19.99. With doubles, 5 * 19.99 is 99.94999999999999.
    expect(CartItem.fromProduct(palette, quantity: 5).lineTotalCents, 9995);
  });

  test('withQuantity returns a new line and leaves this one unchanged', () {
    final item = CartItem.fromProduct(mascara);

    final more = item.withQuantity(4);

    expect(more.quantity, 4);
    expect(more.unitPriceCents, 999);
    expect(item.quantity, 1);
  });

  test('two lines with the same values are equal', () {
    expect(CartItem.fromProduct(mascara), CartItem.fromProduct(mascara));
    expect(
      CartItem.fromProduct(mascara),
      isNot(CartItem.fromProduct(mascara, quantity: 2)),
    );
  });

  group('JSON', () {
    test('toJson writes exactly the five saved fields', () {
      expect(CartItem.fromProduct(mascara, quantity: 2).toJson(), {
        'productId': 1,
        'title': 'Essence Mascara Lash Princess',
        'thumbnailUrl': mascara.thumbnailUrl,
        'unitPriceCents': 999,
        'quantity': 2,
      });
    });

    test('fromJson reads back what toJson wrote', () {
      final item = CartItem.fromProduct(mascara, quantity: 2);

      expect(CartItem.fromJson(item.toJson()), item);
    });

    test('a field with the wrong type is a FormatException naming it', () {
      final json = CartItem.fromProduct(mascara).toJson()..['quantity'] = 'two';

      expect(
        () => CartItem.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(
              'Could not read CartItem: there is a problem with '
              '"quantity"',
            ),
          ),
        ),
      );
    });
  });
}
