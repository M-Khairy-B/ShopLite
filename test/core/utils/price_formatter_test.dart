import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/utils/price_formatter.dart';

void main() {
  group('formatPrice', () {
    test('formats a price under ten dollars', () {
      expect(formatPrice(999), '\$9.99');
    });

    test('formats a typical price', () {
      expect(formatPrice(1999), '\$19.99');
    });

    test('pads cents below 10 with a leading zero', () {
      expect(formatPrice(5), '\$0.05');
    });

    test('shows two zeros for whole-dollar prices', () {
      expect(formatPrice(1000), '\$10.00');
    });

    test('formats zero', () {
      expect(formatPrice(0), '\$0.00');
    });

    test('formats a large price', () {
      expect(formatPrice(199999), '\$1999.99');
    });

    test('rejects negative amounts', () {
      expect(() => formatPrice(-1), throwsA(isA<AssertionError>()));
    });
  });
}
