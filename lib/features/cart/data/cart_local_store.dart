import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_commerce_learn/features/cart/data/models/cart.dart';

/// Keeps the cart on the device, so it survives closing the app.
///
/// Saved as JSON text under one [key] in shared_preferences: small,
/// not secret data. (Tokens go in secure storage, in Phase 7.)
///
/// Each line keeps the price from when it was added, also across restarts:
/// a cart saved last week shows last week's prices. That is fine for
/// display only. The order's real total is worked out by the server, from
/// its own prices (Phase 9).
class CartLocalStore {
  CartLocalStore(this._preferences);

  /// The key the cart is saved under.
  static const key = 'cart';

  final SharedPreferencesWithCache _preferences;

  /// The saved cart, or an empty one if nothing was saved.
  ///
  /// Synchronous: the preferences were read into memory when they were
  /// opened (see `openAppPreferences`).
  ///
  /// Saved data that can't be read (damaged, or from an incompatible
  /// version) gives an empty cart instead of a crash: the next save then
  /// replaces it. A user who can't open the app at all would lose more.
  Cart load() {
    final saved = _preferences.getString(key);
    if (saved == null) {
      return const Cart.empty(); // the first launch
    }
    try {
      final json = jsonDecode(saved);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('The saved cart is not a JSON object.');
      }
      return _withinLimits(Cart.fromJson(json));
    } on FormatException catch (error) {
      _log('Could not read the saved cart, so it starts empty. $error');
      return const Cart.empty();
    }
  }

  /// Saves [cart], replacing what was saved before.
  ///
  /// If the device refuses (a full disk), the cart stays in memory and this
  /// is logged: the next change saves it again. Only device errors are
  /// caught. A bug in this code still shows.
  Future<void> save(Cart cart) async {
    try {
      await _preferences.setString(key, jsonEncode(cart.toJson()));
    } on PlatformException catch (error) {
      _log('Could not save the cart. $error');
    }
  }

  /// [cart] with every line following today's rules. Saved data may not:
  /// it could come from an older version of the app, or have been edited.
  /// Above the limit becomes the limit; below 1 isn't a line at all.
  Cart _withinLimits(Cart cart) {
    return Cart(
      items: [
        for (final item in cart.items)
          if (item.quantity >= 1)
            item.withQuantity(min(item.quantity, maxQuantityPerItem)),
      ],
    );
  }
}

void _log(String message) {
  if (kDebugMode) {
    debugPrint('[CartLocalStore] $message');
  }
}
