import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/wishlist/data/models/wishlist_item.dart';

import '../../../../helpers/mock_products.dart';

void main() {
  final mascara = mockProducts[0]; // id 1, $9.99

  test('fromProduct copies what the wishlist shows, with the price now', () {
    final item = WishlistItem.fromProduct(mascara);

    expect(item.productId, 1);
    expect(item.title, 'Essence Mascara Lash Princess');
    expect(item.thumbnailUrl, mascara.thumbnailUrl);
    expect(item.priceCents, 999);
  });

  test('two entries with the same values are equal', () {
    expect(
      WishlistItem.fromProduct(mascara),
      WishlistItem.fromProduct(mascara),
    );
    expect(
      WishlistItem.fromProduct(mascara),
      isNot(WishlistItem.fromProduct(mockProducts[1])),
    );
  });

  group('JSON', () {
    test('toJson writes exactly the four saved fields', () {
      expect(WishlistItem.fromProduct(mascara).toJson(), {
        'productId': 1,
        'title': 'Essence Mascara Lash Princess',
        'thumbnailUrl': mascara.thumbnailUrl,
        'priceCents': 999,
      });
    });

    test('fromJson reads back what toJson wrote', () {
      final item = WishlistItem.fromProduct(mascara);

      expect(WishlistItem.fromJson(item.toJson()), item);
    });

    test('a missing field is a FormatException naming it', () {
      final json = WishlistItem.fromProduct(mascara).toJson()..remove('title');

      expect(
        () => WishlistItem.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(
              'Could not read WishlistItem: there is a problem with "title"',
            ),
          ),
        ),
      );
    });
  });
}
