import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:e_commerce_learn/features/cart/data/cart_local_store.dart';
import 'package:e_commerce_learn/features/cart/data/models/cart.dart';
import 'package:e_commerce_learn/features/wishlist/data/models/wishlist.dart';
import 'package:e_commerce_learn/features/wishlist/data/wishlist_local_store.dart';

/// A [CartLocalStore] that keeps the cart in memory, and remembers every
/// save, so a test can check what was saved, and when.
class FakeCartStore implements CartLocalStore {
  FakeCartStore([this.saved = const Cart.empty()]);

  /// What [load] returns: what was saved last.
  Cart saved;

  /// Every cart passed to [save], in order.
  final saves = <Cart>[];

  @override
  Cart load() => saved;

  @override
  Future<void> save(Cart cart) async {
    saves.add(cart);
    saved = cart;
  }
}

/// Like [FakeCartStore], for the wishlist.
class FakeWishlistStore implements WishlistLocalStore {
  FakeWishlistStore([this.saved = const Wishlist.empty()]);

  Wishlist saved;
  final saves = <Wishlist>[];

  @override
  Wishlist load() => saved;

  @override
  Future<void> save(Wishlist wishlist) async {
    saves.add(wishlist);
    saved = wishlist;
  }
}

/// Makes the device storage an in-memory map that starts with [values], so
/// real stores can be tested without a phone.
///
/// Then open it as main.dart does, with `openAppPreferences()`. Opening it
/// again later, after the test saved something, reads the map as it is then:
/// what a restarted app would find on the device.
void useInMemoryDeviceStorage([Map<String, Object> values = const {}]) {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData(values);
}
