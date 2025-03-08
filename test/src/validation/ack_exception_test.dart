import 'package:ack/ack.dart';
import 'package:ack/src/context.dart';
import 'package:test/test.dart';

class _MockSchemaContext extends SchemaContext {
  _MockSchemaContext()
      : super(name: 'test', schema: ObjectSchema({}), value: null);
}

void main() {
  group('AckException', () {
    test('toMap() returns error map', () {
      // Create a SchemaConstraintsError containing the constraint errors
      final constraintErrors = [
        NonNullableViolation(),
        InvalidTypeViolation(
          valueType: String,
          expectedType: int,
        ),
      ];

      final schemaError = SchemaConstraintViolation(
        constraints: constraintErrors,
        context: _MockSchemaContext(),
      );
      final exception = AckViolationException(schemaError);
      final map = exception.toMap();

      // Now checks a single 'error' field instead of 'errors' list
      expect(map.containsKey('violation'), isTrue);

      // Check the structure of the error
      final errorMap = map['violation'] as Map<String, dynamic>;
      expect(errorMap['key'], 'constraints');

      // Verify the constraints are included
      final constraintsList = schemaError.constraints;
      expect(constraintsList.length, 2);
      expect(constraintsList[0].key, 'non_nullable_value');
      expect(constraintsList[1].key, 'invalid_type');
    });

    test('toString() includes error details', () {
      final constraintError = NonNullableViolation();
      final schemaError = SchemaConstraintViolation(
        constraints: [constraintError],
        context: _MockSchemaContext(),
      );
      final exception = AckViolationException(schemaError);

      final value = exception.toString();

      expect(
        value,
        contains('$AckViolationException'),
      );
      expect(
        value,
        contains('non_nullable_value'),
      );
    });
  });
}
