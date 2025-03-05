import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaError', () {
    group('InvalidTypeConstraintError', () {
      test('toMap() returns correct structure', () {
        final error = InvalidTypeConstraintError(
          valueType: String,
          expectedType: int,
        );

        final map = error.toMap();

        expect(map, {
          'key': 'invalid_type',
          'message': 'Invalid type of String, expected int',
          'context': {
            'value_type': 'String',
            'expected_type': 'int',
          },
        });
      });

      test('renderMessage() with custom renderer', () {
        final error = InvalidTypeConstraintError(
          valueType: String,
          expectedType: int,
        );

        final message = error.renderMessage(
          (key, value) => '[$key: $value]',
        );

        expect(message, 'Invalid type of String, expected int');
      });
    });

    group('SchemaConstraintsError', () {
      test('single constraint error', () {
        final constraintError = NonNullableValueConstraintError();
        final error = SchemaConstraintsError.single(constraintError);

        expect(error.constraints.length, 1);
        expect(error.constraints.first, constraintError);
      });

      test('multiple constraint errors', () {
        final errors = [
          NonNullableValueConstraintError(),
          InvalidTypeConstraintError(
            valueType: String,
            expectedType: int,
          ),
        ];
        final error = SchemaConstraintsError.multiple(errors);

        expect(error.constraints.length, 2);
        expect(error.constraints, errors);
      });
    });

    group('ObjectSchemaPropertiesError', () {
      test('toMap() includes nested errors', () {
        final nestedError = NonNullableValueConstraintError();
        final error = ObjectSchemaPropertiesError(
          errors: {'field': SchemaConstraintsError.single(nestedError)},
        );

        final map = error.toMap();
        expect(map['context'], {
          'errors': {
            'field': {
              'key': 'constraints',
              'message': 'Schema Constraints Validation failed',
              'constraints': [
                nestedError.toMap(),
              ],
            },
          },
        });
      });
    });

    group('ListSchemaItemsError', () {
      test('toMap() includes indexed errors', () {
        final itemError = NonNullableValueConstraintError();
        final error = ListSchemaItemsError(
          errors: {0: SchemaConstraintsError.single(itemError)},
        );

        final map = error.toMap();
        expect(map['context'], {
          'errors': {
            0: {
              'key': 'constraints',
              'message': 'Schema Constraints Validation failed',
              'constraints': [
                itemError.toMap(),
              ],
            },
          },
        });
      });
    });

    test('toString() returns formatted string', () {
      final error = NonNullableValueConstraintError();
      expect(
        error.toString(),
        contains('NonNullableValueConstraintError:'),
      );
      expect(
        error.toString(),
        contains('non_nullable_value'),
      );
    });
  });
}
