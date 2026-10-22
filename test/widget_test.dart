import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/app/app.dart';

void main() {
  testWidgets('App shell shows welcome text', (WidgetTester tester) async {
    await tester.pumpWidget(const ShopLiteApp());

    expect(find.text('Welcome to ShopLite'), findsOneWidget);
  });
}
