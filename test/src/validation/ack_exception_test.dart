import 'package:ack/ack.dart';
import 'package:test/test.dart';

import 'constraint_error_test.dart';

void main() {
  late MockContext mockContext;

  setUp(() {
    mockContext = MockContext({});
  });

  group('AckException', () {
    test('toMap() returns error map', () {
      // Create a SchemaConstraintsError containing the constraint errors
      final constraintErrors = [
        NonNullableValueConstraintError(context: mockContext),
        InvalidTypeConstraintError(
          valueType: String,
          expectedType: int,
          context: mockContext,
        ),
      ];

      final schemaError = SchemaConstraintViolation.multiple(
        constraintErrors,
        context: mockContext,
      );
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
      final constraintError =
          NonNullableValueConstraintError(context: mockContext);
      final schemaError = SchemaConstraintViolation.single(
        constraintError,
        context: mockContext,
      );
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
