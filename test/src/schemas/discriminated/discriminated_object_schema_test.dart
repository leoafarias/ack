import 'package:ack/ack.dart';
import 'package:test/test.dart';

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
      expect(error, isA<NonNullableSchemaError>());
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
      expect(error, isA<InvalidTypeSchemaError>());
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
      expect((result as Fail).error, isA<SchemaConstraintsError>());
      final error = (result as Fail).error as SchemaConstraintsError;
      expect(error.getConstraint('discriminator_value'), isNotNull);
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
      expect((result as Fail).error, isA<SchemaConstraintsError>());
      final error = (result as Fail).error as SchemaConstraintsError;
      expect(error.getConstraint('discriminator_value'), isNotNull);
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
      expect((result as Fail).error, isA<SchemaConstraintsError>());
      final error = (result as Fail).error as SchemaConstraintsError;
      expect(error.getConstraint('discriminator_schema_structure'), isNotNull);
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

      final error = (result as Fail).error as SchemaNestedError;

      // Check that the 'value' property has an error
      expect(error.errors.any((e) => e.name == 'value'), isTrue);

      // Check that it's an invalid type error
      final valueError = error.errors[0] as InvalidTypeSchemaError;
      expect(valueError, isA<InvalidTypeSchemaError>());
    });
  });
}
