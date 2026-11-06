import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/home_screen.dart';
import 'package:e_commerce_learn/features/products/presentation/screens/product_details_screen.dart';
import 'package:e_commerce_learn/features/wishlist/presentation/cubits/wishlist_cubit.dart';

import '../helpers/pump_app.dart';

/// The [WishlistCubit] that the widget of type [T] finds above it.
WishlistCubit _wishlistFrom<T extends Widget>(WidgetTester tester) {
  return tester.element(find.byType(T)).read<WishlistCubit>();
}

void main() {
  testWidgets('every screen finds the same wishlist', (tester) async {
    await pumpShopLiteApp(tester);
    final fromHome = _wishlistFrom<HomeScreen>(tester);

    await tester.tap(find.text('Essence Mascara Lash Princess'));
    await tester.pumpAndSettle();

    expect(_wishlistFrom<ProductDetailsScreen>(tester), same(fromHome));
  });

  testWidgets('the wishlist is closed when the app goes away', (tester) async {
    await pumpShopLiteApp(tester);
    final wishlist = _wishlistFrom<HomeScreen>(tester);

    await tester.pumpWidget(const SizedBox());

    expect(wishlist.isClosed, isTrue);
  });
}
