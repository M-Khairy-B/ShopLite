import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/features/cart/data/models/cart.dart';
import 'package:e_commerce_learn/features/cart/data/models/cart_item.dart';
import 'package:e_commerce_learn/features/cart/presentation/cubits/cart_cubit.dart';

import '../../../../helpers/mock_products.dart';

void main() {
  final mascara = mockProducts[0]; // id 1, $9.99
  final palette = mockProducts[1]; // id 2, $19.99

  /// A cart with 2 mascaras and 1 palette, made with [Cart]'s own methods.
  Cart twoLines() => const Cart.empty().add(mascara, quantity: 2).add(palette);

  test('starts with an empty cart', () {
    final cubit = CartCubit();

    expect(cubit.state, const Cart.empty());

    cubit.close();
  });

  group('add', () {
    blocTest<CartCubit, Cart>(
      'emits the cart with the product in it',
      build: CartCubit.new,
      act: (cubit) => cubit.add(mascara),
      expect: () => [const Cart.empty().add(mascara)],
    );

    blocTest<CartCubit, Cart>(
      'adding the same product again raises its quantity',
      build: CartCubit.new,
      act: (cubit) => cubit
        ..add(mascara)
        ..add(mascara, quantity: 2),
      expect: () => [
        const Cart.empty().add(mascara),
        const Cart.empty().add(mascara, quantity: 3),
      ],
    );

    test('returns how many it really added, so the screen can say so', () {
      final cubit = CartCubit();
      addTearDown(cubit.close);

      expect(cubit.add(mascara, quantity: 3), 3);
      expect(cubit.add(mascara, quantity: 9), 7); // 3 + 7 = the limit
      expect(cubit.add(mascara), 0); // already full
      expect(cubit.state.quantityOf(1), maxQuantityPerItem);
    });
  });

  group('remove', () {
    blocTest<CartCubit, Cart>(
      'emits the cart without that line',
      build: CartCubit.new,
      seed: twoLines,
      act: (cubit) => cubit.remove(1),
      expect: () => [const Cart.empty().add(palette)],
    );

    blocTest<CartCubit, Cart>(
      'a product that is not in the cart emits nothing',
      build: CartCubit.new,
      seed: twoLines,
      act: (cubit) => cubit.remove(99),
      expect: () => <Cart>[],
    );

    // No seed on purpose: a seed counts as a first emit, and Cubit only
    // skips equal states after one. A new cubit must check by itself.
    blocTest<CartCubit, Cart>(
      'on a new, empty cubit it emits nothing either',
      build: CartCubit.new,
      act: (cubit) => cubit.remove(99),
      expect: () => <Cart>[],
    );
  });

  group('increment', () {
    blocTest<CartCubit, Cart>(
      'adds one to that line',
      build: CartCubit.new,
      seed: twoLines,
      act: (cubit) => cubit.increment(2),
      expect: () => [twoLines().updateQuantity(2, 2)],
    );

    blocTest<CartCubit, Cart>(
      'a product that is not in the cart emits nothing (it is not added)',
      build: CartCubit.new,
      seed: twoLines,
      act: (cubit) => cubit.increment(99),
      expect: () => <Cart>[],
    );
  });

  group('the limit of $maxQuantityPerItem per product', () {
    /// A cart with [quantity] mascaras.
    Cart mascaras(int quantity) =>
        const Cart.empty().add(mascara, quantity: quantity);

    blocTest<CartCubit, Cart>(
      'add past the limit stops at it',
      build: CartCubit.new,
      seed: () => mascaras(8),
      act: (cubit) => cubit.add(mascara, quantity: 4),
      expect: () => [mascaras(maxQuantityPerItem)],
    );

    blocTest<CartCubit, Cart>(
      'increment at the limit emits nothing, and does not throw',
      build: CartCubit.new,
      seed: () => mascaras(maxQuantityPerItem),
      act: (cubit) => cubit.increment(1),
      expect: () => <Cart>[],
      verify: (cubit) => expect(cubit.state.quantityOf(1), 10),
    );

    blocTest<CartCubit, Cart>(
      'increment up to the limit still works',
      build: CartCubit.new,
      seed: () => mascaras(9),
      act: (cubit) => cubit.increment(1),
      expect: () => [mascaras(10)],
    );
  });

  group('decrement', () {
    blocTest<CartCubit, Cart>(
      'takes one from that line',
      build: CartCubit.new,
      seed: twoLines,
      act: (cubit) => cubit.decrement(1),
      expect: () => [twoLines().updateQuantity(1, 1)],
    );

    blocTest<CartCubit, Cart>(
      'stops at 1: the line stays, and nothing is emitted',
      build: CartCubit.new,
      seed: twoLines,
      act: (cubit) => cubit.decrement(2), // the palette: quantity 1
      expect: () => <Cart>[],
      verify: (cubit) => expect(cubit.state.quantityOf(2), 1),
    );

    blocTest<CartCubit, Cart>(
      'a product that is not in the cart emits nothing',
      build: CartCubit.new,
      seed: twoLines,
      act: (cubit) => cubit.decrement(99),
      expect: () => <Cart>[],
    );
  });

  group('restore', () {
    blocTest<CartCubit, Cart>(
      'puts a removed line back where it was',
      build: CartCubit.new,
      seed: twoLines,
      act: (cubit) {
        final removed = cubit.state.items[0];
        cubit
          ..remove(1)
          ..restore(0, removed);
      },
      expect: () => [const Cart.empty().add(palette), twoLines()],
    );

    blocTest<CartCubit, Cart>(
      'a product that is in the cart again emits nothing',
      build: CartCubit.new,
      seed: twoLines,
      act: (cubit) => cubit.restore(0, CartItem.fromProduct(mascara)),
      expect: () => <Cart>[],
    );
  });

  group('clear', () {
    blocTest<CartCubit, Cart>(
      'emits an empty cart',
      build: CartCubit.new,
      seed: twoLines,
      act: (cubit) => cubit.clear(),
      expect: () => [const Cart.empty()],
    );

    blocTest<CartCubit, Cart>(
      'an empty cart stays as it is: nothing is emitted',
      build: CartCubit.new,
      act: (cubit) => cubit.clear(),
      expect: () => <Cart>[],
    );
  });
}
