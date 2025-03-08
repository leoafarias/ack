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
      test('toMap() returns correct structure', () {
        final error = InvalidTypeViolation(
          valueType: String,
          expectedType: int,
        );

        final map = error.toMap();

        expect(map, {
          'key': 'invalid_type',
          'message': 'Invalid type of String, expected int',
          'extra': {
            'value_type': 'String',
            'expected_type': 'int',
          },
        });
      });

      test('renderMessage() with custom renderer', () {
        final error = InvalidTypeViolation(
          valueType: String,
          expectedType: int,
        );

        final message = error.render(
          customRenderer: (entry) => '<value>${entry.value}</value>',
        );

        expect(message,
            'Invalid type of <value>String</value>, expected <value>int</value>');
      });
    });

    group('SchemaConstraintsError', () {
      test('single constraint error', () {
        final constraintError = NonNullableViolation();
        final error = SchemaConstraintViolation(
          constraints: [constraintError],
          context: _MockSchemaContext(),
        );

        expect(error.constraints.length, 1);
        expect(error.constraints.first, constraintError);
      });

      test('multiple constraint errors', () {
        final errors = [
          NonNullableViolation(),
          InvalidTypeViolation(
            valueType: String,
            expectedType: int,
          ),
        ];
        final error = SchemaConstraintViolation(
          constraints: errors,
          context: _MockSchemaContext(),
        );

        expect(error.constraints.length, 2);
        expect(error.constraints, errors);
      });
    });

    group('ObjectSchemaError', () {
      test('toMap() includes nested errors', () {
        final nestedError = NonNullableViolation();
        final error = ObjectSchemaViolation(
          violations: {
            'field': SchemaConstraintViolation(
              constraints: [nestedError],
              context: _MockSchemaContext(),
            )
          },
          context: _MockSchemaContext(),
        );

        final map = error.extra;
        expect(map, {
          'violations': {
            'field': {
              'key': 'constraints',
              'message': 'Total of 1 constraint violations',
              'extra': {
                'constraints': [
                  {
                    'key': 'non_nullable_value',
                    'message': 'Non nullable value is null'
                  }
                ]
              },
              'context': {'name': 'test', 'value': null}
            }
          }
        });
      });
    });

    group('ListSchemaError', () {
      test('toMap() includes indexed errors', () {
        final itemError = NonNullableViolation();
        final error = ListSchemaViolation(
          violations: {
            0: SchemaConstraintViolation(
              constraints: [itemError],
              context: _MockSchemaContext(),
            )
          },
          context: _MockSchemaContext(),
        );

        final map = error.extra;
        expect(map, {
          'violations': {
            0: {
              'key': 'constraints',
              'message': 'Total of 1 constraint violations',
              'extra': {
                'constraints': [
                  {
                    'key': 'non_nullable_value',
                    'message': 'Non nullable value is null'
                  }
                ]
              },
              'context': {'name': 'test', 'value': null}
            }
          }
        });
      });
    });

    test('toString() returns formatted string', () {
      final error = NonNullableViolation();
      expect(
        error.toString(),
        contains('NonNullableViolation:'),
      );
      expect(
        error.toString(),
        contains('non_nullable_value'),
      );
    });
  });
}
