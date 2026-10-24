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
}
