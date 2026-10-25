import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/utils/text_format.dart';

void main() {
  group('capitalize', () {
    test('makes the first letter upper case', () {
      expect(capitalize('laptops'), 'Laptops');
    });

    test('leaves an already capitalized word unchanged', () {
      expect(capitalize('Beauty'), 'Beauty');
    });

    test('returns an empty string unchanged', () {
      expect(capitalize(''), '');
    });
  });

  group('ratingSemanticsLabel', () {
    test('says the rating with one decimal, out of 5', () {
      expect(ratingSemanticsLabel(2.56), 'Rated 2.6 out of 5');
    });
  });
}
