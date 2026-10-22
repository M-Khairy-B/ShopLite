import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/app/app.dart';
import 'package:e_commerce_learn/app/theme/app_theme.dart';
import 'package:e_commerce_learn/features/products/data/mock_products.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/product_details_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_card.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_image.dart';

// Screen sizes in physical pixels, with the pixel ratio of each device.
const _phonePortrait = Size(1080, 2400); // 411 x 914 dp at 2.625
const _phoneLandscape = Size(2400, 1080); // 914 x 411 dp at 2.625
const _phonePixelRatio = 2.625;
const _tabletPortrait = Size(1600, 2560); // 800 x 1280 dp at 2.0
const _tabletPixelRatio = 2.0;

/// The largest text size offered by Android's accessibility settings.
const _largestTextScale = 2.0;

void _setScreen(WidgetTester tester, Size physicalSize, double pixelRatio) {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.reset);
}

void _setTextScale(WidgetTester tester, double scale) {
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Counts the product cards whose top edge lines up with the first card.
int _cardsInFirstRow(WidgetTester tester) {
  final cards = find.byType(ProductCard);
  final firstRowTop = tester.getTopLeft(cards.first).dy;
  var count = 0;
  for (var i = 0; i < cards.evaluate().length; i++) {
    if (tester.getTopLeft(cards.at(i)).dy == firstRowTop) {
      count++;
    }
  }
  return count;
}

Widget _detailsApp() {
  return MaterialApp(
    theme: buildAppTheme(),
    home: ProductDetailsScreen(product: mockProducts.first),
  );
}

void main() {
  group('Home screen', () {
    testWidgets('shows 2 columns on a phone', (tester) async {
      _setScreen(tester, _phonePortrait, _phonePixelRatio);
      await tester.pumpWidget(const ShopLiteApp());

      expect(_cardsInFirstRow(tester), 2);
    });

    testWidgets('shows more columns on a tablet', (tester) async {
      _setScreen(tester, _tabletPortrait, _tabletPixelRatio);
      await tester.pumpWidget(const ShopLiteApp());

      expect(_cardsInFirstRow(tester), 4);
    });

    testWidgets('has no overflow with the largest text size', (tester) async {
      _setScreen(tester, _phonePortrait, _phonePixelRatio);
      _setTextScale(tester, _largestTextScale);
      await tester.pumpWidget(const ShopLiteApp());

      expect(tester.takeException(), isNull);
    });

    testWidgets('category chips grow to fit the largest text size', (
      tester,
    ) async {
      _setScreen(tester, _phonePortrait, _phonePixelRatio);
      _setTextScale(tester, _largestTextScale);
      await tester.pumpWidget(const ShopLiteApp());

      // Chips clip their label instead of throwing an overflow error, so we
      // check directly that the label fits inside its chip.
      final chipBottom = tester.getBottomLeft(find.byType(ChoiceChip).first).dy;
      final labelBottom = tester.getBottomLeft(find.text('All')).dy;
      expect(labelBottom, lessThanOrEqualTo(chipBottom));
    });

    testWidgets('category chips start at the left edge on a wide screen', (
      tester,
    ) async {
      _setScreen(tester, _phoneLandscape, _phonePixelRatio);
      await tester.pumpWidget(const ShopLiteApp());

      // 12 dp is the chip row's horizontal padding.
      expect(tester.getTopLeft(find.byType(ChoiceChip).first).dx, 12);
    });

    testWidgets('has no overflow on a landscape phone', (tester) async {
      _setScreen(tester, _phoneLandscape, _phonePixelRatio);
      await tester.pumpWidget(const ShopLiteApp());

      expect(tester.takeException(), isNull);
    });
  });

  group('Product details screen', () {
    testWidgets('has no overflow with the largest text size', (tester) async {
      _setScreen(tester, _phonePortrait, _phonePixelRatio);
      _setTextScale(tester, _largestTextScale);
      await tester.pumpWidget(_detailsApp());

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the details beside the image on a wide screen', (
      tester,
    ) async {
      _setScreen(tester, _phoneLandscape, _phonePixelRatio);
      await tester.pumpWidget(_detailsApp());

      final title = find.text(mockProducts.first.title);
      expect(title, findsOneWidget);
      expect(
        tester.getTopLeft(title).dx,
        greaterThan(tester.getTopLeft(find.byType(ProductImage)).dx),
      );
    });
  });
}
