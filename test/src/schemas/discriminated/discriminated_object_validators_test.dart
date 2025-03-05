import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../../test_helpers.dart';

void main() {
  group('Discriminated Validators', () {
    test('Fails when discriminator key is missing from the value', () {
      final discriminatedSchema = DiscriminatedObjectSchema(
        discriminatorKey: 'key',
        schemas: {
          'a': ObjectSchema(
            {
              'key': StringSchema(),
              'value': IntegerSchema(),
            },
            required: ['key'],
          ),
        },
      );
      final result = discriminatedSchema.validate({'value': 42});
      expect(
        result.isFail,
        isTrue,
      );
      expect(
        result,
        hasOneConstraintError(
          'missing_discriminator_key',
        ),
      );
    });

    test('Fails when no schema is found for the discriminator value', () {
      final schema = DiscriminatedObjectSchema(
        discriminatorKey: 'key',
        schemas: {
          'a': ObjectSchema(
            {
              'key': StringSchema(),
              'value': IntegerSchema(),
            },
            required: ['key'],
          ),
        },
      );
      final result = schema.validate({'key': 'nonexistent', 'value': 42});
      expect(
        result.isFail,
        isTrue,
      );
      expect(
        result,
        hasOneConstraintError(
          'no_schema_for_discriminator_value',
        ),
      );
    });

    test('Fails when discriminator key is not required in the selected schema',
        () {
      final schemaWithoutRequired = ObjectSchema(
        {
          'key': StringSchema(),
          'value': IntegerSchema(),
        },
        additionalProperties: true,
        required: [],
      );
      final discriminatedSchema = DiscriminatedObjectSchema(
        discriminatorKey: 'key',
        schemas: {'a': schemaWithoutRequired},
      );

      final result = discriminatedSchema.validate({'key': 'a', 'value': 42});
      expect(
        result.isFail,
        isTrue,
      );
      expect(
        result,
        hasOneConstraintError(
          'key_must_be_required_in_schema',
        ),
      );
    });

    test('Fails when underlying schema validation fails', () {
      final discriminatedSchema = DiscriminatedObjectSchema(
        discriminatorKey: 'key',
        schemas: {
          'a': ObjectSchema(
            {
              'value': IntegerSchema(),
              'key': StringSchema(),
            },
            required: ['key'],
          ),
        },
      );
      final result =
          discriminatedSchema.validate({'key': 'a', 'value': 'not an int'});

      expect(
        (result as Fail).error,
        isA<DiscriminatedSchemaError>(),
      );

      final resultError = (result as Fail).error;

      // Since error structure changed from a flat list to a hierarchical structure
      expect(resultError, isA<DiscriminatedSchemaError>());

      final discriminatedError = resultError as DiscriminatedSchemaError;
      expect(discriminatedError.discriminator, 'a');

      // The inner error is an ObjectSchemaPropertiesError
      expect(discriminatedError.error, isA<ObjectSchemaPropertiesError>());

      final propertiesError =
          discriminatedError.error as ObjectSchemaPropertiesError;

      // Check that the 'value' property has an error
      expect(propertiesError.errors.containsKey('value'), isTrue);

      // Check that it's an invalid type error
      final valueError = propertiesError.errors['value']!;
      expect(valueError, isA<SchemaConstraintsError>());

      final constraintsError = valueError as SchemaConstraintsError;
      expect(
        constraintsError.constraints,
        contains(isA<InvalidTypeConstraintError>()),
      );
    });
  });
}
