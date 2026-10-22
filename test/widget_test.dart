import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/app/app.dart';
import 'package:e_commerce_learn/features/products/presentation/widgets/product_card.dart';

void main() {
  testWidgets('App starts on the home screen with a product grid', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ShopLiteApp());

    expect(find.text('ShopLite'), findsOneWidget);
    expect(find.text('Essence Mascara Lash Princess'), findsOneWidget);
    expect(find.byType(ProductCard), findsWidgets);
  });
}
