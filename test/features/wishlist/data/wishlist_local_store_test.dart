import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/app/app_preferences.dart';
import 'package:e_commerce_learn/features/wishlist/data/models/wishlist.dart';
import 'package:e_commerce_learn/features/wishlist/data/wishlist_local_store.dart';

import '../../../helpers/fake_stores.dart';
import '../../../helpers/mock_products.dart';

/// A store on device storage that starts with [saved] under the wishlist's
/// key.
Future<WishlistLocalStore> _storeWith(String? saved) async {
  // `?saved`: the entry is left out when [saved] is null.
  useInMemoryDeviceStorage({WishlistLocalStore.key: ?saved});
  return WishlistLocalStore(await openAppPreferences());
}

void main() {
  test('with nothing saved, loads an empty wishlist', () async {
    final store = await _storeWith(null);

    expect(store.load(), const Wishlist.empty());
  });

  test('a saved wishlist is there after a restart, in order', () async {
    useInMemoryDeviceStorage();
    final wishlist = const Wishlist.empty()
        .toggle(mockProducts[0])
        .toggle(mockProducts[1]);

    await WishlistLocalStore(await openAppPreferences()).save(wishlist);
    final afterRestart = WishlistLocalStore(await openAppPreferences());

    expect(afterRestart.load(), wishlist);
  });

  test('the cart and the wishlist do not overwrite each other', () async {
    final store = await _storeWith(null);

    await store.save(const Wishlist.empty().toggle(mockProducts[0]));
    final reopened = await openAppPreferences();

    expect(reopened.keys, {WishlistLocalStore.key});
  });

  group('saved data that cannot be read gives an empty wishlist', () {
    test('text that is not JSON', () async {
      final store = await _storeWith('not json');

      expect(store.load(), const Wishlist.empty());
    });

    test('JSON that is not an object', () async {
      final store = await _storeWith('"a string"');

      expect(store.load(), const Wishlist.empty());
    });

    test('an object with the wrong shape', () async {
      final store = await _storeWith(jsonEncode({'items': 'none'}));

      expect(store.load(), const Wishlist.empty());
    });
  });
}
