import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../../test_helpers.dart';

void main() {
  group('DiscriminatedMapSchema', () {
    test('copyWith returns a new instance with updated fields', () {
      final validSchemaA = ObjectSchema(
        {
          'value': IntegerSchema(),
          'key': StringSchema(),
        },
        additionalProperties: true,
        required: ['key'],
      );

      final discriminatedSchema = DiscriminatedObjectSchema(
        discriminatorKey: 'key',
        schemas: {'a': validSchemaA},
      );

      final newSchema = discriminatedSchema.copyWith(
        discriminatorKey: 'newType',
        schemas: {'x': validSchemaA},
        nullable: true,
      );
      expect(
          newSchema,
          isNot(
            same(discriminatedSchema),
          ));
      expect(
        newSchema,
        isA<DiscriminatedObjectSchema>(),
      );
    });

    test('Non-nullable schema fails on null', () {
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
      final result = discriminatedSchema.validate(null);

      expect(result.isFail, isTrue);
      final error = (result as Fail).error;
      expect(error, isA<SchemaConstraintsError>());

      final constraintsError = error as SchemaConstraintsError;
      expect(
        constraintsError.constraints.any((e) => e.key == 'non_nullable_value'),
        isTrue,
      );
    });

    test('Nullable schema passes on null', () {
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
      final nullableSchema = discriminatedSchema.copyWith(nullable: true);
      final result = nullableSchema.validate(null);
      expect(
        result.isOk,
        isTrue,
      );
    });

    test('Invalid type returns invalid type error', () {
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
      final result = discriminatedSchema.validate('not a map');

      expect(result.isFail, isTrue);
      final error = (result as Fail).error;
      expect(error, isA<SchemaConstraintsError>());

      final constraintsError = error as SchemaConstraintsError;
      expect(
        constraintsError.constraints.any((e) => e.key == 'invalid_type'),
        isTrue,
      );
    });

    test('Valid discriminated object passes validation', () {
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
      final result = discriminatedSchema.validate({'key': 'a', 'value': 42});
      expect(
        result.isOk,
        isTrue,
      );
    });

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

      final error = (result as Fail).error as ObjectSchemaError;

      // Check that the 'value' property has an error
      expect(error.errors.containsKey('value'), isTrue);

      // Check that it's an invalid type error
      final valueError = error.errors['value']!;
      expect(valueError, isA<SchemaConstraintsError>());

      final constraintsError = valueError as SchemaConstraintsError;
      expect(
        constraintsError.constraints,
        contains(isA<InvalidTypeConstraintError>()),
      );
    });
  });
}
