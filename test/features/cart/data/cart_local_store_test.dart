import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:e_commerce_learn/app/app_preferences.dart';
import 'package:e_commerce_learn/features/cart/data/cart_local_store.dart';
import 'package:e_commerce_learn/features/cart/data/models/cart.dart';
import 'package:e_commerce_learn/features/cart/data/models/cart_item.dart';

import '../../../helpers/fake_stores.dart';
import '../../../helpers/mock_products.dart';

/// A store on device storage that starts with [saved] under the cart's key.
Future<CartLocalStore> _storeWith(String? saved) async {
  // `?saved`: the entry is left out when [saved] is null.
  useInMemoryDeviceStorage({CartLocalStore.key: ?saved});
  return CartLocalStore(await openAppPreferences());
}

/// What a saved line looks like, with [quantity].
Map<String, Object> _savedLine(int productId, int quantity) {
  return CartItem.fromProduct(
    mockProducts.firstWhere((product) => product.id == productId),
    quantity: quantity,
  ).toJson().cast();
}

/// Device storage whose writes always fail, like a full disk.
final class _FailingDeviceStorage extends InMemorySharedPreferencesAsync {
  _FailingDeviceStorage() : super.empty();

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) {
    throw PlatformException(code: 'disk-full');
  }
}

void main() {
  final mascara = mockProducts[0]; // id 1
  final palette = mockProducts[1]; // id 2

  test('with nothing saved, loads an empty cart', () async {
    final store = await _storeWith(null);

    expect(store.load(), const Cart.empty());
  });

  test('a saved cart is there after a restart', () async {
    useInMemoryDeviceStorage();
    final cart = const Cart.empty().add(mascara, quantity: 3).add(palette);

    await CartLocalStore(await openAppPreferences()).save(cart);
    // A new store on newly opened storage: nothing is left in memory from
    // before, as after closing the app.
    final afterRestart = CartLocalStore(await openAppPreferences());

    expect(afterRestart.load(), cart);
  });

  test('saves the cart as JSON text, under its own key', () async {
    final store = await _storeWith(null);

    await store.save(const Cart.empty().add(mascara));
    final reopened = await openAppPreferences();

    expect(jsonDecode(reopened.getString(CartLocalStore.key)!), {
      'items': [_savedLine(1, 1)],
    });
  });

  group('saved data that cannot be read gives an empty cart, not a crash', () {
    test('text that is not JSON', () async {
      final store = await _storeWith('{not json');

      expect(store.load(), const Cart.empty());
    });

    test('JSON that is not an object', () async {
      final store = await _storeWith('[1, 2, 3]');

      expect(store.load(), const Cart.empty());
    });

    test('an object with the wrong shape', () async {
      final store = await _storeWith(
        jsonEncode({
          'items': [
            {'productId': 'one'},
          ],
        }),
      );

      expect(store.load(), const Cart.empty());
    });
  });

  group('saved quantities are brought within the rules', () {
    test(
      'above $maxQuantityPerItem is lowered to $maxQuantityPerItem',
      () async {
        final store = await _storeWith(
          jsonEncode({
            'items': [_savedLine(1, 25), _savedLine(2, 2)],
          }),
        );

        final cart = store.load();

        expect(cart.quantityOf(1), maxQuantityPerItem);
        expect(cart.quantityOf(2), 2);
      },
    );

    test(
      'below 1, the line is dropped, and the others kept in order',
      () async {
        final store = await _storeWith(
          jsonEncode({
            'items': [_savedLine(1, 0), _savedLine(2, 1), _savedLine(6, -3)],
          }),
        );

        expect(store.load().items.map((item) => item.productId), [2]);
      },
    );
  });

  test('a failed save does not throw: the cart is still in memory', () async {
    SharedPreferencesAsyncPlatform.instance = _FailingDeviceStorage();
    final store = CartLocalStore(await openAppPreferences());

    await expectLater(store.save(const Cart.empty().add(mascara)), completes);
  });
}
