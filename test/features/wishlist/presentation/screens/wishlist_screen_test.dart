import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:e_commerce_learn/core/widgets/price_text.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/home_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/product_details_screen.dart';
import 'package:e_commerce_learn/features/profile/presentation/screens/profile_screen.dart';
import 'package:e_commerce_learn/features/wishlist/presentation/cubits/wishlist_cubit.dart';
import 'package:e_commerce_learn/features/wishlist/presentation/screens/wishlist_screen.dart';

import '../../../../helpers/mock_products.dart';
import '../../../../helpers/pump_app.dart';

final _mascara = mockProducts[0]; // id 1, $9.99
final _palette = mockProducts[1]; // id 2, $19.99
const _mascaraTitle = 'Essence Mascara Lash Princess';
const _paletteTitle = 'Eyeshadow Palette with Mirror';

/// A new wishlist cubit, closed after the test.
WishlistCubit _wishlist() {
  final wishlist = WishlistCubit();
  addTearDown(wishlist.close);
  return wishlist;
}

/// The "Remove from wishlist" button on the line of [title].
Finder _removeButton(String title) {
  return find.descendant(
    of: find.widgetWithText(ListTile, title),
    matching: find.byTooltip('Remove from wishlist'),
  );
}

/// Which tab the bottom bar shows as selected.
int _selectedTab(WidgetTester tester) {
  return tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;
}

void main() {
  testWidgets('the Profile tab has a Wishlist entry that opens it', (
    tester,
  ) async {
    await pumpAppAt(tester, '/profile');

    await tester.tap(find.text('Wishlist'));
    await tester.pumpAndSettle();
    expect(find.byType(WishlistScreen), findsOne);
    expect(_selectedTab(tester), 3); // still the Profile tab

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOne);
  });

  testWidgets('an empty wishlist says how to fill it', (tester) async {
    await pumpAppAt(tester, '/profile/wishlist');

    expect(find.text('Your wishlist is empty'), findsOne);

    await tester.tap(find.text('Start shopping'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOne);
    expect(_selectedTab(tester), 0);
  });

  testWidgets('shows the saved products, newest first, with their price', (
    tester,
  ) async {
    final wishlist = _wishlist()
      ..toggle(_mascara)
      ..toggle(_palette);
    await pumpAppAt(tester, '/profile/wishlist', wishlist: wishlist);

    expect(
      tester.getTopLeft(find.text(_paletteTitle)).dy,
      lessThan(tester.getTopLeft(find.text(_mascaraTitle)).dy),
    );
    expect(find.widgetWithText(PriceText, r'$19.99'), findsOne);
    expect(find.widgetWithText(PriceText, r'$9.99'), findsOne);
  });

  testWidgets('the heart removes a product at once, with no Undo', (
    tester,
  ) async {
    final wishlist = _wishlist()
      ..toggle(_mascara)
      ..toggle(_palette);
    await pumpAppAt(tester, '/profile/wishlist', wishlist: wishlist);

    await tester.tap(_removeButton(_mascaraTitle));
    await tester.pump();

    expect(wishlist.state.contains(1), isFalse);
    expect(find.text(_mascaraTitle), findsNothing);
    expect(find.text(_paletteTitle), findsOne);
    expect(find.byType(SnackBar), findsNothing);
  });

  // Found on the emulator: inside a ListTile, the heart was grey.
  testWidgets('the heart is a saved heart: selected, in the primary color', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpAppAt(
      tester,
      '/profile/wishlist',
      wishlist: _wishlist()..toggle(_mascara),
    );

    final heart = _removeButton(_mascaraTitle);
    final drawn = tester.widget<RichText>(
      find.descendant(of: heart, matching: find.byType(RichText)),
    );
    expect(
      drawn.text.style?.color,
      Theme.of(tester.element(heart)).colorScheme.primary,
    );
    expect(
      tester.getSemantics(heart),
      isSemantics(hasSelectedState: true, isSelected: true),
    );

    semantics.dispose();
  });

  testWidgets('removing the last product shows the empty state', (
    tester,
  ) async {
    await pumpAppAt(
      tester,
      '/profile/wishlist',
      wishlist: _wishlist()..toggle(_mascara),
    );

    await tester.tap(_removeButton(_mascaraTitle));
    await tester.pump();

    expect(find.text('Your wishlist is empty'), findsOne);
  });

  testWidgets('a product opens inside the Profile tab, and back returns', (
    tester,
  ) async {
    await pumpAppAt(
      tester,
      '/profile/wishlist',
      wishlist: _wishlist()..toggle(_mascara),
    );

    await tester.tap(find.text(_mascaraTitle));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailsScreen), findsOne);
    expect(_selectedTab(tester), 3);
    // Its address says where it is. ('/product/1' would look the same on
    // screen, but it is Home's address: a link to it opens in Home.)
    expect(
      GoRouterState.of(tester.element(find.byType(ProductDetailsScreen))).uri
          .toString(),
      '/profile/wishlist/product/1',
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(WishlistScreen), findsOne);
  });

  testWidgets('a product removed on its details screen leaves the list', (
    tester,
  ) async {
    await pumpAppAt(
      tester,
      '/profile/wishlist',
      wishlist: _wishlist()..toggle(_mascara),
    );

    await tester.tap(find.text(_mascaraTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remove from wishlist'));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Your wishlist is empty'), findsOne);
  });
}
