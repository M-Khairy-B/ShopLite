import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/app/app.dart';
import 'package:e_commerce_learn/app/app_preferences.dart';
import 'package:e_commerce_learn/features/cart/data/cart_local_store.dart';
import 'package:e_commerce_learn/features/cart/presentation/widgets/cart_tab_icon.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_card.dart';
import 'package:e_commerce_learn/features/wishlist/data/wishlist_local_store.dart';
import 'package:e_commerce_learn/features/wishlist/presentation/widgets/wishlist_button.dart';

import '../helpers/fake_products_repository.dart';
import '../helpers/fake_stores.dart';

const _mascaraTitle = 'Essence Mascara Lash Princess';
const _paletteTitle = 'Eyeshadow Palette with Mirror';

/// Starts the app the way main.dart does: storage opened first, then the
/// real stores on it. Without waiting for anything after the first frame.
Future<void> _launchApp(WidgetTester tester) async {
  final preferences = await openAppPreferences();
  await tester.pumpWidget(
    ShopLiteApp(
      productsRepository: FakeProductsRepository(),
      cartStore: CartLocalStore(preferences),
      wishlistStore: WishlistLocalStore(preferences),
    ),
  );
}

/// [finder] inside the card of [productTitle].
Finder _inCard(String productTitle, Finder finder) {
  return find.descendant(
    of: find.widgetWithText(ProductCard, productTitle),
    matching: finder,
  );
}

/// The text of the Cart tab's badge, or `null` when it is hidden.
String? _badgeText(WidgetTester tester) {
  final badge = tester.widget<Badge>(
    find.descendant(of: find.byType(CartTabIcon), matching: find.byType(Badge)),
  );
  return badge.isLabelVisible ? (badge.label! as Text).data : null;
}

void main() {
  testWidgets('the cart and the wishlist survive closing the app', (
    tester,
  ) async {
    useInMemoryDeviceStorage();
    await _launchApp(tester);
    await tester.pumpAndSettle();

    await tester.tap(_inCard(_mascaraTitle, find.byTooltip('Add to cart')));
    await tester.tap(_inCard(_paletteTitle, find.byType(WishlistButton)));
    await tester.pumpAndSettle();

    // Closed: the whole app leaves the screen, and its cubits are closed.
    await tester.pumpWidget(const SizedBox());
    // Opened again, on the same device storage, with nothing left in
    // memory: storage is opened anew, and new cubits load from it.
    await _launchApp(tester);
    await tester.pumpAndSettle();

    expect(_badgeText(tester), '1');
    final paletteHeart = find.descendant(
      of: _inCard(_paletteTitle, find.byType(WishlistButton)),
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(paletteHeart).isSelected, isTrue);
  });

  testWidgets('the very first frame already shows the saved cart', (
    tester,
  ) async {
    useInMemoryDeviceStorage();
    await _launchApp(tester);
    await tester.pumpAndSettle();
    await tester.tap(_inCard(_mascaraTitle, find.byTooltip('Add to cart')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());

    await _launchApp(tester); // one frame, nothing awaited after it

    expect(_badgeText(tester), '1');
  });
}
