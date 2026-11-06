import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/wishlist/data/models/wishlist.dart';
import 'package:e_commerce_learn/features/wishlist/presentation/cubits/wishlist_cubit.dart';

import '../../../../helpers/fake_stores.dart';
import '../../../../helpers/mock_products.dart';

void main() {
  final mascara = mockProducts[0]; // id 1
  final palette = mockProducts[1]; // id 2

  test('starts with an empty wishlist', () {
    final cubit = WishlistCubit();

    expect(cubit.state, const Wishlist.empty());

    cubit.close();
  });

  group('with a store', () {
    test('starts from the saved wishlist', () {
      final saved = const Wishlist.empty().toggle(mascara);
      final cubit = WishlistCubit(store: FakeWishlistStore(saved));
      addTearDown(cubit.close);

      expect(cubit.state, saved);
    });

    test('saves every change, and only changes', () {
      final store = FakeWishlistStore();
      final cubit = WishlistCubit(store: store);
      addTearDown(cubit.close);

      cubit
        ..toggle(mascara)
        ..toggle(palette)
        ..remove(99) // not saved: no change
        ..remove(1);

      expect(store.saves, [
        const Wishlist.empty().toggle(mascara),
        const Wishlist.empty().toggle(mascara).toggle(palette),
        const Wishlist.empty().toggle(palette),
      ]);
    });
  });

  group('toggle', () {
    blocTest<WishlistCubit, Wishlist>(
      'emits the wishlist with the product saved',
      build: WishlistCubit.new,
      act: (cubit) => cubit.toggle(mascara),
      expect: () => [const Wishlist.empty().toggle(mascara)],
    );

    blocTest<WishlistCubit, Wishlist>(
      'a second tap emits the wishlist without it',
      build: WishlistCubit.new,
      act: (cubit) => cubit
        ..toggle(mascara)
        ..toggle(mascara),
      expect: () => [
        const Wishlist.empty().toggle(mascara),
        const Wishlist.empty(),
      ],
    );
  });

  group('remove', () {
    blocTest<WishlistCubit, Wishlist>(
      'emits the wishlist without that product',
      build: WishlistCubit.new,
      seed: () => const Wishlist.empty().toggle(mascara).toggle(palette),
      act: (cubit) => cubit.remove(1),
      expect: () => [const Wishlist.empty().toggle(palette)],
    );

    // No seed on purpose: a seed counts as a first emit, and Cubit only
    // skips equal states after one. A new cubit must check by itself.
    blocTest<WishlistCubit, Wishlist>(
      'a product that is not saved emits nothing, even on a new cubit',
      build: WishlistCubit.new,
      act: (cubit) => cubit.remove(99),
      expect: () => <Wishlist>[],
    );
  });
}
