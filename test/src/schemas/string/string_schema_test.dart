import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('StringSchema', () {
    test('copyWith changes nullable property', () {
      final schema = StringSchema(nullable: false);
      final newSchema = schema.copyWith(nullable: true);
      final result = newSchema.validate(null);
      expect(result.isOk, isTrue);
    });

    test('copyWith changes constraints', () {
      final schema = StringSchema(constraints: [MaxLengthStringValidator(5)]);
      expect(schema.getConstraints().length, equals(1));
      expect(schema.getConstraints()[0], isA<MaxLengthStringValidator>());

      final newSchema =
          schema.copyWith(constraints: [MinLengthStringValidator(10)]);
      expect(newSchema.getConstraints().length, equals(1));
      expect(newSchema.getConstraints()[0], isA<MinLengthStringValidator>());
    });

    group('StringSchema Basic Validation', () {
      test('Non-nullable schema fails on null', () {
        final schema = StringSchema();
        final result = schema.validate(null);
        expect(result.isFail, isTrue);

        final error = (result as Fail).error;
        expect(error, isA<NonNullableSchemaViolation>());
      });

      test('Nullable schema passes on null', () {
        final schema = StringSchema(nullable: true);
        final result = schema.validate(null);
        expect(result.isOk, isTrue);
      });

      test('Invalid type returns invalid type error', () {
        final schema = StringSchema();
        final result = schema.validate(123); // Not a string.
        expect(result.isOk, isTrue);

        final strictSchema = StringSchema(strict: true);
        final strictResult = strictSchema.validate(123);
        expect(strictResult.isFail, isTrue);

        final error = (strictResult as Fail).error;
        expect(error, isA<InvalidTypeSchemaViolation>());
      });

      test('Valid string passes with no constraints', () {
        final schema = StringSchema();
        final result = schema.validate("hello");
        expect(result.isOk, isTrue);
      });
    });

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
        expect(result.isFail, isTrue);

        final error = (result as Fail).error;
        expect(error, isA<SchemaConstraintViolation>());

        final constraintsError = error as SchemaConstraintViolation;
        expect(
          constraintsError.getConstraint('email'),
          isNotNull,
        );
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
        expect(result.isFail, isTrue);

        final error = (result as Fail).error;
        expect(error, isA<SchemaConstraintViolation>());

        final constraintsError = error as SchemaConstraintViolation;
        expect(
          constraintsError.getConstraint('hex_color'),
          isNotNull,
        );
      });
    });

    group('IsEmptyValidator', () {
      final validator = IsEmptyStringValidator();

      test('Empty string passes validation', () {
        expect(validator.isValid(''), isTrue);
      });

      test('Non-empty string fails validation', () {
        expect(validator.isValid('not empty'), isFalse);
      });

      test('schema validation works with isEmpty validator', () {
        final schema = StringSchema().isEmpty();
        expect(schema.validate('').isOk, isTrue);

        final result = schema.validate('not empty');
        expect(result.isFail, isTrue);

        final error = (result as Fail).error;
        expect(error, isA<SchemaConstraintViolation>());

        final constraintsError = error as SchemaConstraintViolation;
        expect(
          constraintsError.getConstraint('is_empty'),
          isNotNull,
        );
      });
    });

    group('MinLengthValidator', () {
      final validator = MinLengthStringValidator(3);

      test('String longer than min length passes validation', () {
        expect(validator.isValid('abcd'), isTrue);
      });

      test('String equal to min length passes validation', () {
        expect(validator.isValid('abc'), isTrue);
      });

      test('String shorter than min length fails validation', () {
        expect(validator.isValid('ab'), isFalse);
      });

      test('schema validation works with minLength validator', () {
        final schema = StringSchema().minLength(3);
        expect(schema.validate('abc').isOk, isTrue);

        final result = schema.validate('ab');
        expect(result.isFail, isTrue);

        final error = (result as Fail).error;
        expect(error, isA<SchemaConstraintViolation>());

        final constraintsError = error as SchemaConstraintViolation;
        expect(
          constraintsError.getConstraint('min_length'),
          isNotNull,
        );
      });
    });

    group('MaxLengthValidator', () {
      final validator = MaxLengthStringValidator(3);

      test('String shorter than max length passes validation', () {
        expect(validator.isValid('ab'), isTrue);
      });

      test('String equal to max length passes validation', () {
        expect(validator.isValid('abc'), isTrue);
      });

      test('String longer than max length fails validation', () {
        expect(validator.isValid('abcd'), isFalse);
      });

      test('schema validation works with maxLength validator', () {
        final schema = StringSchema().maxLength(3);
        expect(schema.validate('abc').isOk, isTrue);

        final result = schema.validate('abcd');
        expect(result.isFail, isTrue);

        final error = (result as Fail).error;
        expect(error, isA<SchemaConstraintViolation>());

        final constraintsError = error as SchemaConstraintViolation;
        expect(
          constraintsError.getConstraint('max_length'),
          isNotNull,
        );
      });
    });

    group('NotOneOfValidator', () {
      final validator = NotOneOfStringValidator(['red', 'green', 'blue']);

      test('Value not in disallowed list passes validation', () {
        expect(validator.isValid('yellow'), isTrue);
      });

      test('Value in disallowed list fails validation', () {
        expect(validator.isValid('red'), isFalse);
        expect(validator.isValid('green'), isFalse);
        expect(validator.isValid('blue'), isFalse);
      });

      test('schema validation works with notOneOf validator', () {
        final schema = StringSchema().notOneOf(['red', 'green', 'blue']);
        expect(schema.validate('yellow').isOk, isTrue);

        final result = schema.validate('red');
        expect(result.isFail, isTrue);

        final error = (result as Fail).error;
        expect(error, isA<SchemaConstraintViolation>());

        final constraintsError = error as SchemaConstraintViolation;
        expect(
          constraintsError.getConstraint('not_one_of'),
          isNotNull,
        );
      });
    });

    group('NotEmptyValidator', () {
      final validator = NotEmptyStringValidator();

      test('Non-empty string passes validation', () {
        expect(validator.isValid('not empty'), isTrue);
      });

      test('Empty string fails validation', () {
        expect(validator.isValid(''), isFalse);
      });

      test('schema validation works with notEmpty validator', () {
        final schema = StringSchema().isNotEmpty();
        expect(schema.validate('not empty').isOk, isTrue);

        final result = schema.validate('');
        expect(result.isFail, isTrue);

        final error = (result as Fail).error;
        expect(error, isA<SchemaConstraintViolation>());

        final constraintsError = error as SchemaConstraintViolation;
        expect(
          constraintsError.getConstraint('not_empty'),
          isNotNull,
        );
      });
    });

    group('DateTimeValidator', () {
      final validator = DateTimeStringValidator();

      test('Valid ISO 8601 datetime passes validation', () {
        expect(validator.isValid('2023-01-01T00:00:00.000Z'), isTrue);
        expect(validator.isValid('2023-12-31T23:59:59.999Z'), isTrue);
      });

      test('Invalid datetime fails validation', () {
        expect(validator.isValid('not-a-date'), isFalse);
        expect(validator.isValid('2023-13-T12'), isFalse);
      });

      test('schema validation works with datetime validator', () {
        final schema = StringSchema().isDateTime();
        expect(schema.validate('2023-01-01T00:00:00.000Z').isOk, isTrue);

        final result = schema.validate('not-a-date');
        expect(result.isFail, isTrue);

        final error = (result as Fail).error;
        expect(error, isA<SchemaConstraintViolation>());

        final constraintsError = error as SchemaConstraintViolation;
        expect(
          constraintsError.getConstraint('date_time'),
          isNotNull,
        );
      });
    });

    group('DateValidator', () {
      final validator = DateStringValidator();

      test('Valid date string passes validation', () {
        expect(validator.isValid('2023-01-01'), isTrue);
        expect(validator.isValid('2023-12-31'), isTrue);
      });

      test('Invalid date string fails validation', () {
        expect(validator.isValid('not-a-date'), isFalse);
        expect(validator.isValid('2023-13-01'), isFalse);
        expect(validator.isValid('2023/01/01'), isFalse);
      });

      test('schema validation works with date validator', () {
        final schema = StringSchema().isDate();
        expect(schema.validate('2023-01-01').isOk, isTrue);

        final result = schema.validate('not-a-date');
        expect(result.isFail, isTrue);

        final error = (result as Fail).error;
        expect(error, isA<SchemaConstraintViolation>());

        final constraintsError = error as SchemaConstraintViolation;
        expect(
          constraintsError.constraints.any((c) => c.constraintName == 'date'),
          isTrue,
        );
      });
    });

    group('EnumValidator', () {
      final validator = EnumStringValidator(['DRAFT', 'PUBLISHED', 'ARCHIVED']);

      test('Valid enum value passes validation', () {
        expect(validator.isValid('DRAFT'), isTrue);
        expect(validator.isValid('PUBLISHED'), isTrue);
        expect(validator.isValid('ARCHIVED'), isTrue);
      });

      test('Invalid enum value fails validation', () {
        expect(validator.isValid('PENDING'), isFalse);
        expect(validator.isValid('draft'), isFalse);
      });

      test('schema validation works with enum validator', () {
        final schema =
            StringSchema().isEnum(['DRAFT', 'PUBLISHED', 'ARCHIVED']);
        expect(schema.validate('DRAFT').isOk, isTrue);

        final result = schema.validate('PENDING');
        expect(result.isFail, isTrue);

        final error = (result as Fail).error;
        expect(error, isA<SchemaConstraintViolation>());

        final constraintsError = error as SchemaConstraintViolation;
        expect(
          constraintsError.constraints.any((c) => c.constraintName == 'enum'),
          isTrue,
        );
      });
    });
  });
}
