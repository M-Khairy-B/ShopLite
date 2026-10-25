import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/home_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_card.dart';

/// The id of the product shown in the first grid cell.
int _firstProductId(WidgetTester tester) {
  return tester.widget<ProductCard>(find.byType(ProductCard).first).product.id;
}

/// Opens the sort sheet from the app bar.
Future<void> _openSortSheet(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Sort products'));
  await tester.pumpAndSettle();
}

/// Opens the sort sheet and picks the option labelled [label].
Future<void> _chooseSort(WidgetTester tester, String label) async {
  await _openSortSheet(tester);
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('choosing a sort reorders the grid', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    expect(_firstProductId(tester), 1);

    await _chooseSort(tester, 'Price: high to low');

    expect(_firstProductId(tester), 78); // the MacBook, $1999.99
  });

  testWidgets('a snackbar confirms the sort, and Undo restores the order', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await _chooseSort(tester, 'Price: high to low');
    expect(find.text('Showing: Price: high to low'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(_firstProductId(tester), 1);
  });

  testWidgets('closing the sheet without choosing changes nothing', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await _openSortSheet(tester);
    await tester.tapAt(const Offset(20, 20)); // the dimmed area above it
    await tester.pumpAndSettle();

    expect(_firstProductId(tester), 1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('sorting works together with the category filter', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.tap(find.text('Laptops'));
    await tester.pump();
    await _chooseSort(tester, 'Price: low to high');

    expect(_firstProductId(tester), 79); // the Asus, cheaper than the MacBook
  });

  testWidgets('the sheet marks the current sort', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await _chooseSort(tester, 'Top rated');
    await _openSortSheet(tester);

    final topRated = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Top rated'),
    );
    expect(topRated.selected, isTrue);
  });

  testWidgets('the sheet fits a landscape phone with the largest text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 1080);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await _openSortSheet(tester);

    expect(tester.takeException(), isNull);
  });
}
