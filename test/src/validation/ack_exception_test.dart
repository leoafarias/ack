import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('AckException', () {
    test('toMap() returns error map', () {
      // Create a SchemaConstraintsError containing the constraint errors
      final constraintErrors = [
        NonNullableValueConstraintError(),
        InvalidTypeConstraintError(
          valueType: String,
          expectedType: int,
        ),
      ];

      final schemaError = SchemaConstraintsError.multiple(constraintErrors);
      final exception = AckException(schemaError);
      final map = exception.toMap();

      // Now checks a single 'error' field instead of 'errors' list
      expect(map.containsKey('error'), isTrue);

      // Check the structure of the error
      final errorMap = map['error'] as Map<String, dynamic>;
      expect(errorMap['key'], 'constraints');

      // Verify the constraints are included
      final constraintsList = schemaError.constraints;
      expect(constraintsList.length, 2);
      expect(constraintsList[0].key, 'non_nullable_value');
      expect(constraintsList[1].key, 'invalid_type');
    });

    test('toString() includes error details', () {
      final constraintError = NonNullableValueConstraintError();
      final schemaError = SchemaConstraintsError.single(constraintError);
      final exception = AckException(schemaError);

      final value = exception.toString();

      expect(
        value,
        contains('AckException:'),
      );
      expect(
        value,
        contains('non_nullable_value'),
      );
    });
  });
}
