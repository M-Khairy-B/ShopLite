import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_commerce_learn/features/wishlist/data/models/wishlist.dart';

/// Keeps the wishlist on the device, so it survives closing the app.
///
/// Works like `CartLocalStore`, under its own [key].
class WishlistLocalStore {
  WishlistLocalStore(this._preferences);

  /// The key the wishlist is saved under.
  static const key = 'wishlist';

  final SharedPreferencesWithCache _preferences;

  /// The saved wishlist, or an empty one if nothing was saved or it can't
  /// be read.
  Wishlist load() {
    final saved = _preferences.getString(key);
    if (saved == null) {
      return const Wishlist.empty(); // the first launch
    }
    try {
      final json = jsonDecode(saved);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('The saved wishlist is not a JSON object.');
      }
      return Wishlist.fromJson(json);
    } on FormatException catch (error) {
      _log('Could not read the saved wishlist, so it starts empty. $error');
      return const Wishlist.empty();
    }
  }

  /// Saves [wishlist], replacing what was saved before. A device error is
  /// logged, not thrown, as in `CartLocalStore.save`.
  Future<void> save(Wishlist wishlist) async {
    try {
      await _preferences.setString(key, jsonEncode(wishlist.toJson()));
    } on PlatformException catch (error) {
      _log('Could not save the wishlist. $error');
    }
  }
}

void _log(String message) {
  if (kDebugMode) {
    debugPrint('[WishlistLocalStore] $message');
  }
}
