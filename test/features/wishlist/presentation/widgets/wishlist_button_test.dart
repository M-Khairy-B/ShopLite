import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/home_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/product_details_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_card.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_grid.dart';
import 'package:e_commerce_learn/features/search/presentation/cubits/search_cubit.dart';
import 'package:e_commerce_learn/features/wishlist/presentation/cubits/wishlist_cubit.dart';
import 'package:e_commerce_learn/features/wishlist/presentation/widgets/wishlist_button.dart';

import '../../../../helpers/mock_products.dart';
import '../../../../helpers/pump_app.dart';

final _mascara = mockProducts[0]; // id 1
const _mascaraTitle = 'Essence Mascara Lash Princess';

/// A new wishlist cubit, closed after the test.
WishlistCubit _wishlist() {
  final wishlist = WishlistCubit();
  addTearDown(wishlist.close);
  return wishlist;
}

/// The heart on the card of [productTitle], whichever way it points.
Finder _cardHeart(String productTitle) {
  return find.descendant(
    of: find.widgetWithText(ProductCard, productTitle),
    matching: find.byType(WishlistButton),
  );
}

/// The tooltip of the heart [heart]: what it would do if tapped.
String? _tooltipOf(WidgetTester tester, Finder heart) {
  return tester
      .widget<IconButton>(
        find.descendant(of: heart, matching: find.byType(IconButton)),
      )
      .tooltip;
}

/// The color [heart]'s icon is really drawn in, after every theme and
/// parent has had its say. (An icon is drawn as a one-letter text.)
Color? _drawnColor(WidgetTester tester, Finder heart) {
  return tester
      .widget<RichText>(
        find.descendant(of: heart, matching: find.byType(RichText)),
      )
      .text
      .style
      ?.color;
}

void main() {
  group('on a product card', () {
    testWidgets('a tap saves the product, without opening it', (tester) async {
      final wishlist = _wishlist();
      await pumpAppAt(tester, '/', wishlist: wishlist);

      expect(_tooltipOf(tester, _cardHeart(_mascaraTitle)), 'Add to wishlist');
      await tester.tap(_cardHeart(_mascaraTitle));
      await tester.pump();

      expect(wishlist.state.contains(1), isTrue);
      expect(find.byType(ProductDetailsScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOne);
    });

    testWidgets('a saved product has a filled heart that removes it', (
      tester,
    ) async {
      await pumpAppAt(tester, '/', wishlist: _wishlist()..toggle(_mascara));

      final heart = _cardHeart(_mascaraTitle);
      expect(_tooltipOf(tester, heart), 'Remove from wishlist');
      expect(
        find.descendant(of: heart, matching: find.byIcon(Icons.favorite)),
        findsOne,
      );
    });

    testWidgets('a second tap removes it again', (tester) async {
      final wishlist = _wishlist();
      await pumpAppAt(tester, '/', wishlist: wishlist);

      await tester.tap(_cardHeart(_mascaraTitle));
      await tester.pump();
      await tester.tap(_cardHeart(_mascaraTitle));
      await tester.pump();

      expect(wishlist.state.isEmpty, isTrue);
      expect(_tooltipOf(tester, _cardHeart(_mascaraTitle)), 'Add to wishlist');
      expect(
        find.descendant(
          of: _cardHeart(_mascaraTitle),
          matching: find.byIcon(Icons.favorite_border),
        ),
        findsOne,
      );
    });

    testWidgets('a screen reader hears whether the product is saved', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpAppAt(tester, '/', wishlist: _wishlist()..toggle(_mascara));

      expect(
        tester.getSemantics(_cardHeart(_mascaraTitle)),
        isSemantics(
          tooltip: 'Remove from wishlist',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
        ),
      );
      expect(
        tester.getSemantics(_cardHeart('Eyeshadow Palette with Mirror')),
        isSemantics(
          tooltip: 'Add to wishlist',
          hasSelectedState: true,
          isSelected: false,
        ),
      );

      semantics.dispose();
    });

    testWidgets('in a category, saves the product', (tester) async {
      final wishlist = _wishlist();
      await pumpAppAt(tester, '/categories/beauty', wishlist: wishlist);

      await tester.tap(_cardHeart(_mascaraTitle));
      await tester.pump();

      expect(wishlist.state.contains(1), isTrue);
    });

    testWidgets('in search results, saves the product', (tester) async {
      final wishlist = _wishlist();
      await pumpAppAt(tester, '/search', wishlist: wishlist);

      await tester.enterText(find.byType(TextField), 'mascara');
      await tester.pump(SearchCubit.debounce);
      await tester.pumpAndSettle();
      await tester.tap(_cardHeart(_mascaraTitle));
      await tester.pump();

      expect(wishlist.state.contains(1), isTrue);
    });

    testWidgets('a change rebuilds that one heart, not the grid or the '
        'other hearts', (tester) async {
      final wishlist = _wishlist();
      await pumpAppAt(tester, '/', wishlist: wishlist);
      // Several cards, so "only one heart" means something.
      expect(find.byType(WishlistButton), findsAtLeast(2));

      // Flutter calls this (in debug builds) for every widget it rebuilds.
      final rebuilt = <Type>[];
      debugOnRebuildDirtyWidget = (element, _) {
        rebuilt.add(element.widget.runtimeType);
      };
      wishlist.toggle(_mascara);
      // The cubit's stream delivers the new state in a microtask, after a
      // plain pump() has checked for work: settle instead.
      await tester.pumpAndSettle();
      debugOnRebuildDirtyWidget = null;

      expect(rebuilt.where((type) => type == WishlistButton), hasLength(1));
      expect(rebuilt, isNot(contains(ProductCard)));
      expect(rebuilt, isNot(contains(ProductGrid)));
    });
  });

  group('on the details screen', () {
    testWidgets('the heart in the app bar saves the product', (tester) async {
      final wishlist = _wishlist();
      await pumpAppAt(tester, '/product/1', wishlist: wishlist);

      await tester.tap(find.byTooltip('Add to wishlist'));
      await tester.pump();

      expect(wishlist.state.contains(1), isTrue);
      expect(find.byTooltip('Remove from wishlist'), findsOne);
    });

    // Found on the emulator: the app bar gave the saved heart its own grey.
    testWidgets('a saved heart has the same color here as on a card', (
      tester,
    ) async {
      await pumpAppAt(tester, '/', wishlist: _wishlist()..toggle(_mascara));
      final primary = Theme.of(tester.element(find.byType(HomeScreen)))
          .colorScheme
          .primary;
      expect(_drawnColor(tester, _cardHeart(_mascaraTitle)), primary);

      await tester.tap(find.text(_mascaraTitle));
      await tester.pumpAndSettle();

      final appBarHeart = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(WishlistButton),
      );
      expect(_drawnColor(tester, appBarHeart), primary);
    });

    testWidgets('it is the same heart as on the card', (tester) async {
      await pumpAppAt(tester, '/', wishlist: _wishlist());

      await tester.tap(find.text(_mascaraTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add to wishlist'));
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(
        _tooltipOf(tester, _cardHeart(_mascaraTitle)),
        'Remove from wishlist',
      );
    });
  });
}
