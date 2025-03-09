import 'package:ack/ack.dart';
import 'package:ack/src/context.dart';
import 'package:test/test.dart';

class _MockSchemaContext extends SchemaContext {
  _MockSchemaContext()
      : super(name: 'test', schema: ObjectSchema({}), value: null);
}

void main() {
  group('SchemaError', () {
    group('InvalidTypeConstraintError', () {
      test('renderMessage() with custom renderer', () {
        final error = InvalidTypeSchemaError(
          valueType: String,
          expectedType: int,
          context: _MockSchemaContext(),
        );

        final message = error.render(
          customRenderer: (key, value) => '<value>$value</value>',
        );

        expect(message,
            'Invalid type of <value>String</value>, expected <value>int</value>');
      });
    });

    group('SchemaConstraintsError', () {
      final constraintError1 = ValidatorError(
        key: 'custom_constraint',
        message: 'Custom constraint',
        variables: {},
      );

      final constraintError2 = ValidatorError(
        key: 'custom_constraint2',
        message: 'Custom constraint 2',
        variables: {},
      );

      test('single constraint error', () {
        final error = SchemaValidationError(
          validations: [constraintError1],
          context: _MockSchemaContext(),
        );

        expect(error.validations.length, 1);
        expect(error.validations.first, constraintError1);
      });

      test('multiple constraint errors', () {
        final error = SchemaValidationError(
          validations: [constraintError1, constraintError2],
          context: _MockSchemaContext(),
        );

        expect(error.validations.length, 2);
        expect(error.validations, [constraintError1, constraintError2]);
      });
    });

    test('toString() returns formatted string', () {
      final error = NonNullableSchemaError(
        context: _MockSchemaContext(),
      );
      expect(
        error.toString(),
        contains('$NonNullableSchemaError'),
      );
      expect(
        error.toString(),
        contains('non_nullable'),
      );
    });
  });

  group('Schema Error Messages', () {
    test('Simple string validation error messages', () {
      final schema = Ack.string.minLength(5).maxLength(10);

      var result = schema.validate('abc');
      expect(result.isFail, isTrue);
      var error = result.getViolation();
      expect(
          error.message,
          contains(
              'The string length (3) is too short; it must be at least 5 characters.'));

      result = schema.validate('abcdefghijk');
      expect(result.isFail, isTrue);
      error = result.getViolation();
      expect(
          error.message,
          contains(
              'The string length (11) exceeds the maximum allowed of 10 characters.'));
    });

    test('Enum validation error messages', () {
      final schema = Ack.string.isEnum(['red', 'green', 'blue']);

      var result = schema.validate('yellow');
      expect(result.isFail, isTrue);
      var error = result.getViolation();
      expect(
          error.message,
          contains(
              'Invalid value "yellow". Allowed values are: [red, green, blue]. (Closest match: "N/A")'));
    });

    test('Date validation error messages', () {
      final schema = Ack.string.isDate();

      var result = schema.validate('2023-13-45');
      expect(result.isFail, isTrue);
      var error = result.getViolation();
      expect(
          error.message,
          contains(
              'The value "2023-13-45" is not a valid date. Expected format: YYYY-MM-DD (e.g., 2017-07-21).'));
    });

    test('List validation error messages', () {
      final schema = Ack.list(Ack.string).minItems(2).maxItems(4).uniqueItems();

      // Test too few items
      var result = schema.validate(['a']);
      expect(result.isFail, isTrue);
      var error = result.getViolation();
      expect(
          error.message,
          contains(
              'The list has only 1 items; at least 2 items are required.'));

      // Test too many items
      result = schema.validate(['a', 'b', 'c', 'd', 'e']);
      expect(result.isFail, isTrue);
      error = result.getViolation();
      expect(
          error.message,
          contains(
              'The list contains 5 items, which exceeds the allowed maximum of 4.'));

      // Test duplicate items
      result = schema.validate(['a', 'b', 'a']);
      expect(result.isFail, isTrue);
      error = result.getViolation();
      expect(
          error.message,
          contains(
              'The list contains duplicate items: [a]. All items must be unique.'));
    });
  });
}
