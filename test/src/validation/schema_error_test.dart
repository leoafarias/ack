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
        final context = _MockSchemaContext();
        final error = InvalidTypeSchemaViolation(
          valueType: String,
          expectedType: int,
          context: context,
        );

        final map = error.toMap();

        expect(map, {
          'key': 'invalid_type',
          'name': 'test',
          'schema': {
            'type': 'object',
            'constraints': [],
            'nullable': false,
            'description': '',
            'defaultValue': null,
            'properties': {},
            'additionalProperties': false,
            'required': []
          },
          'value': null,
          'message': 'Invalid type of String, expected int',
          'variables': {'valueType': 'String', 'expectedType': 'int'}
        });
      });

      test('renderMessage() with custom renderer', () {
        final error = InvalidTypeSchemaViolation(
          valueType: String,
          expectedType: int,
          context: _MockSchemaContext(),
        );

        final message = error.render(
          customRenderer: (entry) => '<value>${entry.value}</value>',
        );

        expect(message,
            'Invalid type of <value>String</value>, expected <value>int</value>');
      });
    });

    group('SchemaConstraintsError', () {
      final constraintError1 = ConstraintViolation(
        key: 'custom_constraint',
        message: 'Custom constraint',
        variables: {},
      );

      final constraintError2 = ConstraintViolation(
        key: 'custom_constraint2',
        message: 'Custom constraint 2',
        variables: {},
      );

      test('single constraint error', () {
        final error = SchemaConstraintViolation(
          constraints: [constraintError1],
          context: _MockSchemaContext(),
        );

        expect(error.constraints.length, 1);
        expect(error.constraints.first, constraintError1);
      });

      test('multiple constraint errors', () {
        final error = SchemaConstraintViolation(
          constraints: [constraintError1, constraintError2],
          context: _MockSchemaContext(),
        );

        expect(error.constraints.length, 2);
        expect(error.constraints, [constraintError1, constraintError2]);
      });
    });

    group('ObjectSchemaError', () {
      test('toMap() includes nested errors', () {
        final nestedError = ConstraintViolation(
          key: 'custom_constraint',
          message: 'Custom constraint',
          variables: {},
        );
        final error = NestedSchemaViolation(
          violations: {
            'field': SchemaConstraintViolation(
              constraints: [nestedError],
              context: _MockSchemaContext(),
            )
          },
          context: _MockSchemaContext(),
        );

        final map = error.variables;
        expect(map, {
          'schema_name': 'test',
          'violations': {
            'field': {
              'key': 'constraints',
              'name': 'test',
              'schema': {
                'type': 'object',
                'constraints': [],
                'nullable': false,
                'description': '',
                'defaultValue': null,
                'properties': {},
                'additionalProperties': false,
                'required': []
              },
              'value': null,
              'message':
                  'Schema on test violated: [{key: custom_constraint, message: Custom constraint}]',
              'variables': {
                'schema_name': 'test',
                'constraints': [
                  {'key': 'custom_constraint', 'message': 'Custom constraint'}
                ]
              }
            }
          }
        });
      });
    });

    group('ListSchemaError', () {
      test('toMap() includes indexed errors', () {
        final itemError = NonNullableSchemaViolation(
          context: _MockSchemaContext(),
        );
        final error = NestedSchemaViolation(
          violations: {'0': itemError},
          context: _MockSchemaContext(),
        );

        final map = error.variables;
        expect(map, {
          'schema_name': 'test',
          'violations': {
            '0': {
              'key': 'non_nullable',
              'name': 'test',
              'schema': {
                'type': 'object',
                'constraints': [],
                'nullable': false,
                'description': '',
                'defaultValue': null,
                'properties': {},
                'additionalProperties': false,
                'required': []
              },
              'value': null,
              'message': 'Non nullable value is null on test',
              'variables': {'schema_name': 'test', 'value': 'N/A'}
            }
          }
        });
      });
    });

    test('toString() returns formatted string', () {
      final error = NonNullableSchemaViolation(
        context: _MockSchemaContext(),
      );
      expect(
        error.toString(),
        contains('$NonNullableSchemaViolation'),
      );
      expect(
        error.toString(),
        contains('non_nullable'),
      );
    });
  });
}
