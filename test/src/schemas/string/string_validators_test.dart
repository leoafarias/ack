import 'package:ack/ack.dart';
import 'package:ack/src/context.dart';
import 'package:test/test.dart';

import '../../../test_helpers.dart';
import '../../validation/constraint_error_test.dart';

void main() {
  group('String Validators', () {
    group('EmailValidator', () {
      final validator = EmailStringValidator();

      test('Valid emails pass validation', () {
        expect(validator.isValid('test@example.com'), isTrue);
        expect(validator.isValid('user.name@domain.com'), isTrue);
        expect(validator.isValid('user+tag@domain.com'), isTrue);
      });

      test('Invalid emails fail validation', () {
        expect(validator.isValid('not-an-email'), isFalse);
        expect(validator.isValid('missing@domain'), isFalse);
        expect(validator.isValid('@domain.com'), isFalse);
        expect(validator.isValid(''), isFalse);
      });

      test('schema validation works with email validator', () {
        final schema = StringSchema().isEmail();
        expect(schema.validate('test@example.com').isOk, isTrue);

        final result = schema.validate('not-an-email');
        expect(result, hasOneConstraintError('email'));
      });
    });

    group('HexColorValidator', () {
      final validator = HexColorStringValidator();

      test('Valid hex colors pass validation', () {
        expect(validator.isValid('#fff'), isTrue);
        expect(validator.isValid('#ffffff'), isTrue);
        expect(validator.isValid('fff'), isTrue);
        expect(validator.isValid('ffffff'), isTrue);
      });

      test('Invalid hex colors fail validation', () {
        expect(validator.isValid('#ff'), isFalse);
        expect(validator.isValid('red'), isFalse);
        expect(validator.isValid('#ggg'), isFalse);
        expect(validator.isValid(''), isFalse);
      });

      test('schema validation works with hex color validator', () {
        final schema = StringSchema().isHexColor();
        expect(schema.validate('#00ff55').isOk, isTrue);

        final result = schema.validate('not-a-color');
        expect(result, hasOneConstraintError('hex_color'));
      });
    });

    group('IsEmptyValidator', () {
      final validator = IsEmptyStringValidator();

      test('Empty string passes validation', () {
        expect(validator.isValid(''), isTrue);
      });

      test('Non-empty strings fail validation', () {
        expect(validator.isValid('not empty'), isFalse);
        expect(validator.isValid(' '), isFalse);
        expect(validator.isValid('a'), isFalse);
      });

      test('schema validation works with isEmpty validator', () {
        final schema = StringSchema().isEmpty();
        expect(schema.validate('').isOk, isTrue);

        final result = schema.validate('not empty');
        expect(result, hasOneConstraintError('is_empty'));
      });
    });

    group('MinLengthValidator', () {
      final validator = MinLengthStringValidator(3);

      test('Strings meeting minimum length pass validation', () {
        expect(validator.isValid('abc'), isTrue);
        expect(validator.isValid('abcd'), isTrue);
        expect(validator.isValid('12345'), isTrue);
      });

      test('Strings below minimum length fail validation', () {
        expect(validator.isValid('a'), isFalse);
        expect(validator.isValid('ab'), isFalse);
        expect(validator.isValid(''), isFalse);
      });

      test('schema validation works with minLength validator', () {
        final schema = StringSchema().minLength(3);
        expect(schema.validate('abc').isOk, isTrue);

        final result = schema.validate('ab');
        expect(result, hasOneConstraintError('min_length'));
      });
    });

    group('MaxLengthValidator', () {
      final validator = MaxLengthStringValidator(3);

      test('Strings within maximum length pass validation', () {
        expect(validator.isValid(''), isTrue);
        expect(validator.isValid('a'), isTrue);
        expect(validator.isValid('ab'), isTrue);
        expect(validator.isValid('abc'), isTrue);
      });

      test('Strings exceeding maximum length fail validation', () {
        expect(validator.isValid('abcd'), isFalse);
        expect(validator.isValid('12345'), isFalse);
      });

      test('schema validation works with maxLength validator', () {
        final schema = StringSchema().maxLength(3);
        expect(schema.validate('abc').isOk, isTrue);

        final result = schema.validate('abcd');
        expect(result, hasOneConstraintError('max_length'));
      });

      test('error message is rendered correctly', () {
        wrapWithViolationContext(MockContext({}), () {
          final error = validator.onError('abcd');
          expect(
            error.message,
            'String must be at most 3 characters long instead of 4',
          );
        });
      });
    });

    group('OneOfValidator', () {
      final validator = OneOfStringValidator(['apple', 'banana']);

      test('Strings in allowed values pass validation', () {
        expect(validator.isValid('apple'), isTrue);
        expect(validator.isValid('banana'), isTrue);
      });

      test('Strings not in allowed values fail validation', () {
        expect(validator.isValid('orange'), isFalse);
        expect(validator.isValid(''), isFalse);
        expect(validator.isValid('APPLE'), isFalse);
      });

      test('schema validation works with oneOf validator', () {
        final schema = StringSchema().oneOf(['apple', 'banana']);
        expect(schema.validate('apple').isOk, isTrue);

        final result = schema.validate('orange');
        expect(result, hasOneConstraintError('one_of'));
      });
    });

    group('NotOneOfValidator', () {
      final validator = NotOneOfStringValidator(['apple', 'banana']);

      test('Strings not in disallowed values pass validation', () {
        expect(validator.isValid('orange'), isTrue);
        expect(validator.isValid(''), isTrue);
        expect(validator.isValid('APPLE'), isTrue);
      });

      test('Strings in disallowed values fail validation', () {
        expect(validator.isValid('apple'), isFalse);
        expect(validator.isValid('banana'), isFalse);
      });

      test('schema validation works with notOneOf validator', () {
        final schema = StringSchema().notOneOf(['apple', 'banana']);
        expect(schema.validate('orange').isOk, isTrue);

        final result = schema.validate('apple');
        expect(result, hasOneConstraintError('not_one_of'));
      });
    });

    group('EnumValidator', () {
      final validator = EnumStringValidator(['red', 'green', 'blue']);

      test('Strings in enum pass validation', () {
        expect(validator.isValid('red'), isTrue);
        expect(validator.isValid('green'), isTrue);
        expect(validator.isValid('blue'), isTrue);
      });

      test('Strings not in enum fail validation', () {
        expect(validator.isValid('yellow'), isFalse);
        expect(validator.isValid(''), isFalse);
        expect(validator.isValid('RED'), isFalse);
      });

      test('schema validation works with enum validator', () {
        final schema = StringSchema().isEnum(['red', 'green', 'blue']);
        expect(schema.validate('red').isOk, isTrue);

        final result = schema.validate('yellow');
        expect(result, hasOneConstraintError('enum'));
      });
    });

    group('NotEmptyValidator', () {
      final validator = NotEmptyStringValidator();

      test('Non-empty strings pass validation', () {
        expect(validator.isValid('hello'), isTrue);
        expect(validator.isValid(' '), isTrue);
        expect(validator.isValid('a'), isTrue);
      });

      test('Empty string fails validation', () {
        expect(validator.isValid(''), isFalse);
      });

      test('schema validation works with notEmpty validator', () {
        final schema = StringSchema().isNotEmpty();
        expect(schema.validate('hello').isOk, isTrue);

        final result = schema.validate('');
        expect(result, hasOneConstraintError('not_empty'));
      });
    });

    group('DateTimeValidator', () {
      final validator = DateTimeStringValidator();

      test('Valid datetime strings pass validation', () {
        expect(validator.isValid('2023-01-01T00:00:00.000Z'), isTrue);
        expect(validator.isValid('2023-12-31T23:59:59.999Z'), isTrue);
        expect(validator.isValid('2023-06-15T12:30:45Z'), isTrue);
      });

      test('Invalid datetime strings fail validation', () {
        expect(validator.isValid('not a datetime'), isFalse);
        expect(validator.isValid('32'), isFalse);
        expect(validator.isValid(''), isFalse);
      });

      test('schema validation works with datetime validator', () {
        final schema = StringSchema().isDateTime();
        expect(schema.validate('2023-01-01T00:00:00.000Z').isOk, isTrue);

        final result = schema.validate('not a datetime');
        expect(result, hasOneConstraintError('date_time'));
      });
    });
  });
}
