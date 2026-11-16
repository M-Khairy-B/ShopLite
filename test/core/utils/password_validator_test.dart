import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/utils/validators.dart';

void main() {
  group('validatePassword', () {
    test('accepts letters and digits, at least 8 long', () {
      expect(validatePassword('abc12345'), isNull);
    });

    group('each rule has its message', () {
      test('1. empty', () {
        expect(validatePassword(null), 'Enter a password');
        expect(validatePassword(''), 'Enter a password');
      });

      test('2. a space at the start or the end', () {
        const message = 'Remove the spaces at the start or end';
        expect(validatePassword(' abc12345'), message);
        expect(validatePassword('abc12345 '), message);
      });

      test('3. too short', () {
        expect(validatePassword('abc1234'), 'Use at least 8 characters');
      });

      test('4. too long', () {
        expect(validatePassword('a' * 64 + '1'), 'Use at most 64 characters');
      });

      test('5. no letter', () {
        expect(validatePassword('12345678'), 'Include at least one letter');
      });

      // The demo account's password: why the login form doesn't use this.
      test('6. no digit', () {
        expect(validatePassword('emilyspass'), 'Include at least one number');
      });
    });

    group('the length limits are inclusive', () {
      test('8 characters is enough', () {
        expect(validatePassword('abcdefg1'), isNull);
      });

      test('64 characters is allowed', () {
        expect(validatePassword('a' * 63 + '1'), isNull);
      });
    });

    group('the first rule that fails gives the message', () {
      test('too short comes before "no digit"', () {
        expect(validatePassword('abc'), 'Use at least 8 characters');
      });

      test('spaces at the ends come before the length', () {
        expect(
          validatePassword(' abc'),
          'Remove the spaces at the start or end',
        );
      });

      test('only spaces is a space problem, not an empty password', () {
        expect(
          validatePassword('        '),
          'Remove the spaces at the start or end',
        );
      });

      test('no letter comes before no digit', () {
        expect(validatePassword('!!!!!!!!'), 'Include at least one letter');
      });
    });

    group('what counts', () {
      test('spaces inside are allowed', () {
        expect(validatePassword('correct horse 42'), isNull);
      });

      test('letters of any alphabet count', () {
        expect(validatePassword('كلمةسرية1'), isNull);
        expect(validatePassword('ÉÉÉÉÉÉÉ1'), isNull);
      });

      test('a digit that is not 0-9 is not a number here', () {
        // ١ is the Arabic-Indic digit one. The rule asks for 0-9.
        expect(validatePassword('abcdefg١'), 'Include at least one number');
      });

      test('symbols are allowed', () {
        expect(validatePassword('p@ss-w0rd!'), isNull);
      });
    });
  });
}
