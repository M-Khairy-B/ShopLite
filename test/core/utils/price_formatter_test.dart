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

    test('groups thousands with commas', () {
      expect(formatPrice(199999), '\$1,999.99');
      expect(formatPrice(123456789), '\$1,234,567.89');
    });

    test('rejects negative amounts', () {
      expect(() => formatPrice(-1), throwsA(isA<AssertionError>()));
    });

    // The formatter divides by 100 to get dollars, a double. Doubles can't
    // hold most cent values exactly (19.99 is really 19.98999…), so this
    // checks every price up to $10,000 still shows exactly its own cents.
    test('shows exactly the given cents, for every price up to \$10,000', () {
      final shape = RegExp(r'^\$\d{1,3}(,\d{3})*\.\d{2}$');
      for (var cents = 0; cents <= 1000000; cents++) {
        final text = formatPrice(cents);
        final digits = text.replaceAll(RegExp(r'[$,.]'), '');
        if (!shape.hasMatch(text) || int.parse(digits) != cents) {
          fail('$cents cents was shown as $text');
        }
      }
    });

    test('shows exactly the given cents for very large totals', () {
      expect(formatPrice(123456789012), '\$1,234,567,890.12');
      expect(formatPrice(999999999999), '\$9,999,999,999.99');
    });
  });
}
