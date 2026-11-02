import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/products/data/models/product.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_grid.dart';

import '../../../../helpers/mock_products.dart';
import '../../../../helpers/pump_app.dart';

/// Shows a [ProductGrid] of [products] that counts its end-reached calls.
class _GridHarness {
  int endReachedCalls = 0;

  Future<void> pump(
    WidgetTester tester,
    List<Product> products, {
    Widget? footer,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductGrid(
            products: products,
            onProductTap: (_) {},
            onEndReached: () => endReachedCalls++,
            footer: footer,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

void main() {
  group('reaching the end', () {
    testWidgets('is not reported at the top of a long grid', (tester) async {
      final harness = _GridHarness();

      await harness.pump(tester, generatedProducts(30));

      expect(harness.endReachedCalls, 0);
    });

    testWidgets('is reported when the user scrolls near the end', (
      tester,
    ) async {
      final harness = _GridHarness();
      await harness.pump(tester, generatedProducts(30));

      await scrollProductGridToEnd(tester);

      expect(harness.endReachedCalls, greaterThan(0));
    });

    testWidgets('is reported when the products do not fill the screen', (
      tester,
    ) async {
      // Nothing to scroll, so no scrolling would ever ask for more.
      final harness = _GridHarness();

      await harness.pump(tester, generatedProducts(2));

      expect(harness.endReachedCalls, 1);
    });

    testWidgets('is checked again when more products arrive', (tester) async {
      final harness = _GridHarness();
      await harness.pump(tester, generatedProducts(2));

      await harness.pump(tester, generatedProducts(4));

      expect(harness.endReachedCalls, 2);
    });

    testWidgets('is not checked again when the products stay the same', (
      tester,
    ) async {
      // For example when only the footer changed.
      final harness = _GridHarness();
      await harness.pump(tester, generatedProducts(2));

      await harness.pump(tester, generatedProducts(2));

      expect(harness.endReachedCalls, 1);
    });
  });

  testWidgets('shows the footer after the last product', (tester) async {
    await _GridHarness().pump(
      tester,
      generatedProducts(30),
      footer: const Text('The footer'),
    );
    expect(find.text('The footer'), findsNothing); // not on screen yet

    await scrollProductGridToEnd(tester);

    expect(find.text('The footer'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('The footer')).dy,
      greaterThan(tester.getBottomLeft(find.text('Product 30')).dy),
    );
  });

  testWidgets('a spinner in the footer only animates near the screen', (
    tester,
  ) async {
    // pumpAndSettle (inside pump) would time out if the spinner, far below
    // the screen, were still asking for a new frame every frame.
    await _GridHarness().pump(
      tester,
      generatedProducts(30),
      footer: const CircularProgressIndicator(),
    );
    expect(tester.binding.hasScheduledFrame, isFalse);

    // Near the end it spins: there is always a next frame.
    await tester.drag(find.byType(ProductGrid), const Offset(0, -100000));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('a product keeps its card when the order changes', (
    tester,
  ) async {
    // The key lets Flutter find "the card of product 1" again after the
    // list changes, instead of rebuilding whatever card is at index 0.
    final [first, second] = generatedProducts(2);
    final harness = _GridHarness();

    await harness.pump(tester, [first, second]);
    final before = tester.element(find.byKey(ValueKey(first.id)));

    await harness.pump(tester, [second, first]);
    final after = tester.element(find.byKey(ValueKey(first.id)));

    expect(after, same(before));
  });
}
