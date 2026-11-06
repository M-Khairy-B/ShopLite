import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/wishlist/data/models/wishlist.dart';
import 'package:e_commerce_learn/features/wishlist/data/models/wishlist_item.dart';

import '../../../../helpers/mock_products.dart';

void main() {
  final mascara = mockProducts[0]; // id 1
  final palette = mockProducts[1]; // id 2
  final perfume = mockProducts[2]; // id 6

  /// The ids in [wishlist], in order.
  List<int> ids(Wishlist wishlist) {
    return [for (final item in wishlist.items) item.productId];
  }

  group('an empty wishlist', () {
    test('has nothing in it', () {
      const wishlist = Wishlist.empty();

      expect(wishlist.isEmpty, isTrue);
      expect(wishlist.contains(1), isFalse);
    });

    test('is equal to a wishlist made from an empty list', () {
      expect(Wishlist(items: const []), const Wishlist.empty());
    });
  });

  group('toggle', () {
    test('saves a product that is not saved', () {
      final wishlist = const Wishlist.empty().toggle(mascara);

      expect(wishlist.contains(1), isTrue);
      expect(wishlist.items.single, WishlistItem.fromProduct(mascara));
      expect(wishlist.isEmpty, isFalse);
    });

    test('puts the newest product first', () {
      final wishlist = const Wishlist.empty()
          .toggle(mascara)
          .toggle(palette)
          .toggle(perfume);

      expect(ids(wishlist), [6, 2, 1]);
    });

    test('removes a product that is saved, and only that one', () {
      final wishlist = const Wishlist.empty()
          .toggle(mascara)
          .toggle(palette)
          .toggle(mascara);

      expect(ids(wishlist), [2]);
      expect(wishlist.contains(1), isFalse);
    });

    test('twice gives back an equal wishlist', () {
      final before = const Wishlist.empty().toggle(mascara);

      expect(before.toggle(palette).toggle(palette), before);
    });

    test('leaves the wishlist it was called on unchanged', () {
      const empty = Wishlist.empty();

      empty.toggle(mascara);

      expect(empty.isEmpty, isTrue);
    });
  });

  group('remove', () {
    test('takes the product out, and keeps the others in order', () {
      final wishlist = const Wishlist.empty()
          .toggle(mascara)
          .toggle(palette)
          .toggle(perfume)
          .remove(2);

      expect(ids(wishlist), [6, 1]);
    });

    test('a product that is not saved changes nothing', () {
      final wishlist = const Wishlist.empty().toggle(mascara);

      expect(wishlist.remove(99), wishlist);
    });
  });

  test('items is read-only', () {
    final wishlist = const Wishlist.empty().toggle(mascara);

    expect(
      () => wishlist.items.add(WishlistItem.fromProduct(palette)),
      throwsUnsupportedError,
    );
  });

  test('changing the list it was made from does not change it', () {
    final list = [WishlistItem.fromProduct(mascara)];
    final wishlist = Wishlist(items: list);

    list.clear();

    expect(wishlist.contains(1), isTrue);
  });

  group('JSON', () {
    test('fromJson reads back what toJson wrote, in order', () {
      final wishlist = const Wishlist.empty().toggle(mascara).toggle(palette);

      expect(Wishlist.fromJson(wishlist.toJson()), wishlist);
    });

    test('toJson writes plain maps, ready to be encoded', () {
      final json = const Wishlist.empty().toggle(mascara).toJson();

      expect(json['items'], [WishlistItem.fromProduct(mascara).toJson()]);
    });

    test('a bad entry is a FormatException that says where', () {
      final json = {
        'items': [
          {'productId': 'one'},
        ],
      };

      expect(
        () => Wishlist.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('Could not read Wishlist'),
              contains('Could not read WishlistItem'),
            ),
          ),
        ),
      );
    });
  });
}
