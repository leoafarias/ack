import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Object Validators', () {
    group('Additional Properties', () {
      test('Fails on additional unallowed property', () {
        final schema = ObjectSchema(
            {
              'age': IntegerSchema(),
            },
            additionalProperties: false,
            required: ['age']);
        final result = schema.validate({'age': 25, 'name': 'John'});

        expect(result.isFail, isTrue);

        final objectError =
            (result as Fail).error as ObjectSchemaPropertiesError;
        expect(objectError.errors.containsKey('name'), isTrue);

        final nameError = objectError.errors['name'];
        expect(nameError, isA<SchemaConstraintsError>());

        final constraintsError = nameError as SchemaConstraintsError;
        expect(
          constraintsError.constraints
              .any((c) => c.key == 'unallowed_property'),
          isTrue,
        );
      });

      test('Allows additional properties when enabled', () {
        final schema = ObjectSchema(
            {
              'age': IntegerSchema(),
            },
            additionalProperties: true,
            required: ['age']);
        final result = schema.validate({'age': 25, 'name': 'John'});

        expect(result.isOk, isTrue);
      });
    });

    group('Required Properties', () {
      test('Fails on missing required property', () {
        final schema = ObjectSchema(
            {
              'age': IntegerSchema(),
              'name': StringSchema(),
            },
            additionalProperties: true,
            required: ['age']);
        final result = schema.validate({'name': 'John'});

        expect(result.isFail, isTrue);

        final objectError =
            (result as Fail).error as ObjectSchemaPropertiesError;
        expect(objectError.errors.containsKey('age'), isTrue);

        final ageError = objectError.errors['age'];
        expect(ageError, isA<SchemaConstraintsError>());

        final constraintsError = ageError as SchemaConstraintsError;
        expect(
          constraintsError.constraints
              .any((c) => c.key == 'property_is_required'),
          isTrue,
        );
      });

      test('Passes when all required properties are present', () {
        final schema = ObjectSchema(
            {
              'age': IntegerSchema(),
              'name': StringSchema(),
            },
            additionalProperties: true,
            required: ['age', 'name']);
        final result = schema.validate({'age': 25, 'name': 'John'});

        expect(result.isOk, isTrue);
      });
    });

    group('Property Validation', () {
      test('Fails on property schema error', () {
        final schema = ObjectSchema(
            {
              'age': IntegerSchema(),
            },
            additionalProperties: true,
            required: ['age']);
        final result = schema.validate({'age': 'not an int'});

        expect(result.isFail, isTrue);

        final objectError =
            (result as Fail).error as ObjectSchemaPropertiesError;
        expect(objectError.errors.containsKey('age'), isTrue);

        final ageError = objectError.errors['age'];
        expect(ageError, isA<SchemaConstraintsError>());

        final constraintsError = ageError as SchemaConstraintsError;
        expect(
          constraintsError.constraints.any((c) => c.key == 'invalid_type'),
          isTrue,
        );
      });

      test('Validates nested object properties', () {
        final schema = ObjectSchema(
          {
            'user': ObjectSchema(
              {
                'age': IntegerSchema(),
                'name': StringSchema(),
              },
              required: [
                'age',
                'name',
              ],
            ),
          },
          required: ['user'],
        );

        final result = schema.validate({
          'user': {'age': 'not an int', 'name': null}
        });

        expect(result.isFail, isTrue);

        final objectError =
            (result as Fail).error as ObjectSchemaPropertiesError;
        final userError =
            objectError.errors['user'] as ObjectSchemaPropertiesError;

        expect(userError.errors['age'], isA<SchemaConstraintsError>());
        expect(userError.errors['name'], isA<SchemaConstraintsError>());
      });
    });

    group('MinProperties Validator', () {
      test('Fails when object has fewer properties than minimum', () {
        final schema = ObjectSchema({
          'age': IntegerSchema(),
          'name': StringSchema(),
          'email': StringSchema(),
        }).minProperties(3);

        final result = schema.validate({'age': 25, 'name': 'John'});
        expect(result.isFail, isTrue);

        final error = (result as Fail).error as SchemaConstraintsError;
        expect(
          error.constraints.any((c) => c.key == 'object_min_properties'),
          isTrue,
        );
      });
    });

    group('MaxProperties Validator', () {
      test('Fails when object has more properties than maximum', () {
        final schema = ObjectSchema({
          'age': IntegerSchema(),
          'name': StringSchema(),
          'email': StringSchema(),
        }).maxProperties(2);

        final result = schema
            .validate({'age': 25, 'name': 'John', 'email': 'john@example.com'});
        expect(result.isFail, isTrue);

        final error = (result as Fail).error as SchemaConstraintsError;
        expect(
          error.constraints.any((c) => c.key == 'object_max_properties'),
          isTrue,
        );
      });
    });
  });
}
