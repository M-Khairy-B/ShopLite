import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_commerce_learn/features/cart/data/cart_local_store.dart';
import 'package:e_commerce_learn/features/wishlist/data/wishlist_local_store.dart';

/// Opens the device storage, and reads everything the app keeps there into
/// memory: after this, reading is instant and needs no `await`.
///
/// The allow list names every key the app uses. Anything else stored on the
/// device is neither read nor changed.
Future<SharedPreferencesWithCache> openAppPreferences() {
  return SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: {CartLocalStore.key, WishlistLocalStore.key},
    ),
  );
}
