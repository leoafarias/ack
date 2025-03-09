import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('ListSchema', () {
    test('copyWith changes nullable property', () {
      final schema = ListSchema(IntegerSchema(), nullable: false);
      final newSchema = schema.copyWith(nullable: true);
      final result = newSchema.validate(null);
      expect(result.isOk, isTrue);
    });

    test('copyWith changes constraints', () {
      final schema = ListSchema<int>(IntegerSchema(),
          constraints: [ListMaxItemsValidator(5)]);
      expect(schema.getConstraints().length, equals(1));
      expect(schema.getConstraints()[0], isA<ListMaxItemsValidator>());

      final newSchema =
          schema.copyWith(constraints: [ListMinItemsValidator(1)]);
      expect(newSchema.getConstraints().length, equals(1));
      expect(newSchema.getConstraints()[0], isA<ListMinItemsValidator>());
    });

    group('ListSchema Basic Validation', () {
      test('Non-nullable schema fails on null', () {
        final schema = ListSchema<int>(IntegerSchema());
        final result = schema.validate(null);
        expect(result.isFail, isTrue);

        final error = (result as Fail).error;
        expect(error, isA<NonNullableSchemaError>());
      });

      test('Nullable schema passes on null', () {
        final schema = ListSchema(IntegerSchema(), nullable: true);
        final result = schema.validate(null);
        expect(result.isOk, isTrue);
      });

      test('Invalid type returns invalid type error', () {
        final schema = ListSchema(IntegerSchema());
        final result = schema.validate('not a list');

        expect(result.isFail, isTrue);

        final error = (result as Fail).error;
        expect(error, isA<InvalidTypeSchemaError>());
      });

      test('Valid list passes with no constraints', () {
        final schema = ListSchema(IntegerSchema());
        final result = schema.validate([1, 2, 3]);
        expect(result.isOk, isTrue);
      });
    });

    group('UniqueItemsValidator', () {
      test('Unique list passes validation', () {
        final validator = UniqueItemsListValidator<int>();
        expect(validator.isValid([1, 2, 3]), isTrue);
      });

      test('Non-unique list fails validation', () {
        final validator = UniqueItemsListValidator<int>();
        expect(validator.isValid([1, 2, 2, 3]), isFalse);
      });

      test('schema validation works with uniqueItems', () {
        final schema = ListSchema(IntegerSchema()).uniqueItems();
        expect(schema.validate([1, 2, 3]).isOk, isTrue);

        final result = schema.validate([1, 2, 2, 3]);
        expect(result.isFail, isTrue);

        final error = (result as Fail).error;
        expect(error, isA<SchemaConstraintsError>());

        final constraintsError = error as SchemaConstraintsError;
        expect(
          constraintsError.getConstraint('list_unique_items'),
          isNotNull,
        );
      });
    });

    group('MinItemsValidator', () {
      test('List with length >= min passes validation', () {
        final validator = ListMinItemsValidator(3);
        expect(validator.isValid([1, 2, 3]), isTrue);
        expect(validator.isValid([1, 2, 3, 4]), isTrue);
      });

      test('List with length < min fails validation', () {
        final validator = ListMinItemsValidator(3);
        expect(validator.isValid([1, 2]), isFalse);
      });

      test('schema validation works with minItems', () {
        final schema = ListSchema(IntegerSchema()).minItems(3);
        expect(schema.validate([1, 2, 3]).isOk, isTrue);

        final result = schema.validate([1, 2]);
        expect(result.isFail, isTrue);

        final error = (result as Fail).error;
        expect(error, isA<SchemaConstraintsError>());

        final constraintsError = error as SchemaConstraintsError;
        expect(
          constraintsError.getConstraint('list_min_items'),
          isNotNull,
        );
      });
    });

    group('MaxItemsValidator', () {
      test('List with length <= max passes validation', () {
        final validator = ListMaxItemsValidator(3);
        expect(validator.isValid([1, 2]), isTrue);
        expect(validator.isValid([1, 2, 3]), isTrue);
      });

      test('List with length > max fails validation', () {
        final validator = ListMaxItemsValidator(3);
        expect(validator.isValid([1, 2, 3, 4]), isFalse);
      });

      test('schema validation works with maxItems', () {
        final schema = ListSchema(IntegerSchema()).maxItems(3);
        expect(schema.validate([1, 2, 3]).isOk, isTrue);

        final result = schema.validate([1, 2, 3, 4]);
        expect(result.isFail, isTrue);

        final error = (result as Fail).error;
        expect(error, isA<SchemaConstraintsError>());

        final constraintsError = error as SchemaConstraintsError;
        expect(
          constraintsError.getConstraint('list_max_items'),
          isNotNull,
        );
      });
    });
  });
}
