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
        final error = InvalidTypeSchemaError(
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
        final error = InvalidTypeSchemaError(
          valueType: String,
          expectedType: int,
          context: _MockSchemaContext(),
        );

        final message = error.render(
          (v) => '<value>$v</value>',
          htmlEscapeValues: false,
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

    group('ObjectSchemaError', () {
      test('toMap() includes nested errors', () {
        final nestedError = ValidatorError(
          key: 'custom_constraint',
          message: 'Custom constraint',
          variables: {},
        );
        final error = NestedSchemaError(
          errors: [
            SchemaValidationError(
              validations: [nestedError],
              context: _MockSchemaContext(),
            )
          ],
          context: _MockSchemaContext(),
        );

        final map = error.variables;
        expect(map, {
          'schemaName': 'test',
          'violations': {
            'field': {
              'key': 'constraints',
              'message':
                  'Schema on test violated: [{key: custom_constraint, message: Custom constraint, key__length: 17, message__length: 17}]',
              'variables': {
                'schemaName': 'test',
                'constraints': [
                  {'key': 'custom_constraint', 'message': 'Custom constraint'}
                ]
              },
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
              'name': 'test'
            }
          }
        });
      });
    });

    group('ListSchemaError', () {
      test('toMap() includes indexed errors', () {
        final itemError = NonNullableSchemaError(
          context: _MockSchemaContext(),
        );
        final error = NestedSchemaError(
          errors: [itemError],
          context: _MockSchemaContext(),
        );

        final map = error.variables;
        expect(map, {
          'schemaName': 'test',
          'violations': {
            '0': {
              'key': 'non_nullable',
              'message': 'Non nullable value is null on test',
              'variables': {'schemaName': 'test', 'value': 'N/A'},
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
              'name': 'test'
            }
          }
        });
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

      // Test too short
      var result = schema.validate('abc');
      expect(result.isFail, isTrue);
      var error = result.getViolation();
      expect(error.message, contains('Too short: 3. Min: 5'));

      // Test too long
      result = schema.validate('abcdefghijk');
      expect(result.isFail, isTrue);
      error = result.getViolation();
      expect(error.message, contains('Too long: 11. Max: 10'));
    });

    test('Enum validation error messages', () {
      final schema = Ack.string.isEnum(['red', 'green', 'blue']);

      var result = schema.validate('yellow');
      expect(result.isFail, isTrue);
      var error = result.getViolation();
      expect(error.message, contains('Invalid enum: yellow'));
      expect(error.message, contains('Must be: [red, green, blue]'));
    });

    test('Date validation error messages', () {
      final schema = Ack.string.isDate();

      var result = schema.validate('2023-13-45');
      expect(result.isFail, isTrue);
      var error = result.getViolation();
      expect(error.message, contains('Invalid date: 2023-13-45'));
      expect(error.message, contains('Expected: YYYY-MM-DD'));
    });

    test('Object validation error messages', () {
      final schema = Ack.object({
        'name': Ack.string.minLength(3),
        'age': Ack.int.min(0),
      }, required: [
        'name',
        'age'
      ]);

      // Test missing required field
      var result = schema.validate({'name': 'Bob'});
      expect(result.isFail, isTrue);
      var error = result.getViolation();
      expect(error, isA<SchemaValidationError>());
      print(error.message);
      // expect(error.message, contains('Missing: age'));

      // Test invalid field value
      result = schema.validate({'name': 'B', 'age': -1});
      expect(result.isFail, isTrue);
      error = result.getViolation();
      print(error.message);
      expect(error.message, contains('Too short: 1. Min: 3'));
      expect(error.message, contains('Too low: -1 < 0'));
    });

    test('List validation error messages', () {
      final schema = Ack.list(Ack.string).minItems(2).maxItems(4).uniqueItems();

      // Test too few items
      var result = schema.validate(['a']);
      expect(result.isFail, isTrue);
      var error = result.getViolation();
      expect(error.message, contains('Too few items: 1. Min: 2'));

      // Test too many items
      result = schema.validate(['a', 'b', 'c', 'd', 'e']);
      expect(result.isFail, isTrue);
      error = result.getViolation();
      expect(error.message, contains('Too many items: 5. Max: 4'));

      // Test duplicate items
      result = schema.validate(['a', 'b', 'a']);
      expect(result.isFail, isTrue);
      error = result.getViolation();
      expect(error.message, contains('Duplicates: [a]'));
    });

    test('Nested object validation error messages', () {
      final schema = Ack.object({
        'user': Ack.object({
          'name': Ack.string.minLength(3),
          'age': Ack.int.min(0),
        }, required: [
          'name',
          'age'
        ]),
        'settings': Ack.object({
          'theme': Ack.string.isEnum(['light', 'dark']),
        }),
      });

      var result = schema.validate({
        'user': {
          'name': 'Bo',
          'age': -5,
        },
        'settings': {
          'theme': 'blue',
        },
      });

      expect(result.isFail, isTrue);
      print(result.getViolation().message);
      // var error = result.getViolation();
      // expect(error.message, contains('Too short: 2. Min: 3'));
      // expect(error.message, contains('Too low: -5 < 0'));
      // expect(error.message, contains('Invalid enum: blue'));
    });
  });
}
