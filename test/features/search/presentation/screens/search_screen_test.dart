import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/core/widgets/loading_view.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/product_details_screen.dart';
import 'package:e_commerce_learn/features/search/presentation/cubits/search_cubit.dart';
import 'package:e_commerce_learn/features/search/presentation/screens/search_screen.dart';

import '../../../../helpers/fake_products_repository.dart';
import '../../../../helpers/mock_products.dart';
import '../../../../helpers/pump_app.dart';

/// Shows only the search screen, on [repository] (the mock catalog by
/// default).
Future<void> _pumpSearchScreen(
  WidgetTester tester, {
  FakeProductsRepository? repository,
}) async {
  await tester.pumpWidget(
    withAppProviders(
      const MaterialApp(home: SearchScreen()),
      repository: repository,
    ),
  );
  await tester.pumpAndSettle();
}

/// Types [text] into the search field, then waits out the pause and the
/// answer.
Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(SearchCubit.debounce);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts by inviting the user to type', (tester) async {
    await _pumpSearchScreen(tester);

    expect(find.text('Search the catalog'), findsOneWidget);
  });

  testWidgets('typing shows the matching products after a pause', (
    tester,
  ) async {
    await _pumpSearchScreen(tester);

    await _search(tester, 'phone');

    expect(find.text('iPhone 5s'), findsOneWidget);
    expect(find.text('iPhone 6'), findsOneWidget);
    expect(find.text('Essence Mascara Lash Princess'), findsNothing);
  });

  testWidgets('typing "phone" quickly sends one search, not five', (
    tester,
  ) async {
    final repository = FakeProductsRepository();
    await _pumpSearchScreen(tester, repository: repository);

    for (final text in ['p', 'ph', 'pho', 'phon', 'phone']) {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(SearchCubit.debounce);
    await tester.pumpAndSettle();

    expect(repository.searchQueries, ['phone']);
  });

  testWidgets("the keyboard's search button searches right away", (
    tester,
  ) async {
    final repository = FakeProductsRepository();
    await _pumpSearchScreen(tester, repository: repository);

    await tester.enterText(find.byType(TextField), 'phone');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump(); // no waiting for the pause

    expect(repository.searchQueries, ['phone']);
    await tester.pumpAndSettle();
  });

  testWidgets('shows a loading view while searching', (tester) async {
    final repository = FakeProductsRepository(gate: Completer<void>());
    await _pumpSearchScreen(tester, repository: repository);

    await tester.enterText(find.byType(TextField), 'phone');
    await tester.pump(SearchCubit.debounce);
    await tester.pump();

    expect(find.byType(LoadingView), findsOneWidget);

    repository.gate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('nothing matching says so', (tester) async {
    await _pumpSearchScreen(tester);

    await _search(tester, 'zzz');

    expect(find.text('No results'), findsOneWidget);
    expect(find.textContaining('"zzz"'), findsOneWidget);
  });

  testWidgets('a failed search shows the error, and "Try again" works', (
    tester,
  ) async {
    final repository = FakeProductsRepository(error: const NetworkException());
    await _pumpSearchScreen(tester, repository: repository);
    await _search(tester, 'phone');
    expect(find.text("You're offline"), findsOneWidget);

    repository.error = null; // the connection is back
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('iPhone 6'), findsOneWidget);
  });

  testWidgets('the clear button empties the field and starts over', (
    tester,
  ) async {
    await _pumpSearchScreen(tester);
    expect(find.byTooltip('Clear search'), findsNothing); // nothing to clear
    await _search(tester, 'phone');

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text('Search the catalog'), findsOneWidget);
    expect(find.byTooltip('Clear search'), findsNothing);
  });

  testWidgets('says so below the results when more match than are shown', (
    tester,
  ) async {
    await _pumpSearchScreen(
      tester,
      repository: FakeProductsRepository(products: generatedProducts(45)),
    );
    await _search(tester, 'product');

    await scrollProductGridToEnd(tester);

    expect(
      find.text(
        'Showing the first 30 of 45 results. Type more to narrow them down.',
      ),
      findsOneWidget,
    );
  });

  group('in the app', () {
    testWidgets("Home's search button opens search; a result opens its "
        'details, and back returns to the results', (tester) async {
      await pumpShopLiteApp(tester);

      await tester.tap(find.byTooltip('Search products'));
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);

      await _search(tester, 'phone');
      await tester.tap(find.text('iPhone 6'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductDetailsScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('iPhone 6'), findsOneWidget);
      expect(find.text('phone'), findsOneWidget); // the field kept its text
    });

    testWidgets('leaving search before the pause is over sends no search', (
      tester,
    ) async {
      final repository = FakeProductsRepository();
      await pumpShopLiteApp(tester, repository: repository);
      await tester.tap(find.byTooltip('Search products'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'phone');
      await tester.pageBack(); // before the pause is over
      await tester.pumpAndSettle();
      await tester.pump(SearchCubit.debounce);

      expect(repository.searchQueries, isEmpty);
    });
  });
}
