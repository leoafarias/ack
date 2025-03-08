import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';

void main() {
  group('SchemaError', () {
    late MockViolationContext mockContext;

    setUp(() {
      mockContext = MockViolationContext();
    });

    group('InvalidTypeConstraintError', () {
      test('toMap() returns correct structure', () {
        final error = InvalidTypeConstraintError(
          valueType: String,
          expectedType: int,
          context: mockContext,
        );

        final map = error.toMap();

        expect(map, {
          'key': 'invalid_type',
          'message': 'Invalid type of String, expected int',
          'context': {
            'extra': {
              'value_type': 'String',
              'expected_type': 'int',
            },
          },
        });
      });

      test('renderMessage() with custom renderer', () {
        final error = InvalidTypeConstraintError(
          valueType: String,
          expectedType: int,
          context: mockContext,
        );

        final message = error.renderMessage(
          (key, value) => '[$key: $value]',
        );

        expect(message, 'Invalid type of String, expected int');
      });
    });

    group('SchemaConstraintsError', () {
      test('single constraint error', () {
        final constraintError = NonNullableValueConstraintError(
          context: mockContext,
        );
        final error = SchemaConstraintViolation.single(
          constraintError,
          context: mockContext,
        );

        expect(error.constraints.length, 1);
        expect(error.constraints.first, constraintError);
      });

      test('multiple constraint errors', () {
        final errors = [
          NonNullableValueConstraintError(context: mockContext),
          InvalidTypeConstraintError(
            valueType: String,
            expectedType: int,
            context: mockContext,
          ),
        ];
        final error = SchemaConstraintViolation.multiple(
          errors,
          context: mockContext,
        );

        expect(error.constraints.length, 2);
        expect(error.constraints, errors);
      });
    });

    group('ObjectSchemaError', () {
      test('toMap() includes nested errors', () {
        final nestedError = NonNullableValueConstraintError(
          context: mockContext,
        );
        final error = ObjectSchemaViolation(
          errors: {
            'field': SchemaConstraintViolation.single(
              nestedError,
              context: mockContext,
            )
          },
          context: mockContext,
        );

        final map = error.context.extra;
        expect(map, {
          'errors': {
            'field': {
              'key': 'constraints',
              'message': 'Schema Constraints Validation failed',
              'constraints': [
                {
                  'key': 'non_nullable_value',
                  'message': 'Non nullable value is null',
                }
              ]
            }
          }
        });
      });
    });

    group('ListSchemaError', () {
      test('toMap() includes indexed errors', () {
        final itemError = NonNullableValueConstraintError(
          context: mockContext,
        );
        final error = ListSchemaViolation(
          errors: {
            0: SchemaConstraintViolation.single(itemError, context: mockContext)
          },
          context: mockContext,
        );

        final map = error.context.extra;
        expect(map, {
          'errors': {
            0: {
              'key': 'constraints',
              'message': 'Schema Constraints Validation failed',
              'constraints': [
                {
                  'key': 'non_nullable_value',
                  'message': 'Non nullable value is null'
                }
              ]
            }
          }
        });
      });
    });

    test('toString() returns formatted string', () {
      final error = NonNullableValueConstraintError(
        context: mockContext,
      );
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
