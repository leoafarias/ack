import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Object Validators', () {
    test('Fails on additional unallowed property', () {
      final schema = ObjectSchema(
          {
            'age': IntegerSchema(),
          },
          additionalProperties: false,
          required: ['age']);
      final result = schema.validate({'age': 25, 'name': 'John'});

      expect(result.isFail, isTrue);

      final objectError = (result as Fail).error as ObjectSchemaPropertiesError;
      expect(objectError.errors.containsKey('name'), isTrue);

      final nameError = objectError.errors['name'];
      expect(nameError, isA<SchemaConstraintsError>());

      final constraintsError = nameError as SchemaConstraintsError;
      expect(
        constraintsError.constraints.any((c) => c.key == 'unallowed_property'),
        isTrue,
      );
    });

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

      final objectError = (result as Fail).error as ObjectSchemaPropertiesError;
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

    test('Fails on property schema error', () {
      final schema = ObjectSchema(
          {
            'age': IntegerSchema(),
          },
          additionalProperties: true,
          required: ['age']);
      final result = schema.validate({'age': 'not an int'});

      expect(result.isFail, isTrue);

      final objectError = (result as Fail).error as ObjectSchemaPropertiesError;
      expect(objectError.errors.containsKey('age'), isTrue);

      final ageError = objectError.errors['age'];
      expect(ageError, isA<SchemaConstraintsError>());

      final constraintsError = ageError as SchemaConstraintsError;
      expect(
        constraintsError.constraints.any((c) => c.key == 'invalid_type'),
        isTrue,
      );
    });
  });
}
