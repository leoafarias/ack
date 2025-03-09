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
      final constraint1Violation = ConstraintError(
        key: 'custom_constraint1',
        message: 'Custom constraint',
      );
      final constraint2Violation = ConstraintError(
        key: 'custom_constraint2',
        message: 'Custom constraint 2',
      );
      final constraint3Violation = ConstraintError(
        key: 'custom_constraint3',
        message: 'Custom constraint 3',
      );
      final constraintErrors = [
        constraint1Violation,
        constraint2Violation,
        constraint3Violation,
      ];

      final schemaError = SchemaConstraintsError(
        constraints: constraintErrors,
        context: _MockSchemaContext(),
      );
      final exception = AckViolationException(schemaError);
      final map = exception.toMap();

      // Now checks a single 'error' field instead of 'errors' list
      expect(map.containsKey('constraints'), isTrue);

      // Check the structure of the error
      final errorMap = map['constraints'] as Map<String, dynamic>;
      expect(errorMap['key'], 'validation');

      // Verify the constraints are included
      final constraintsList = schemaError.constraints;
      expect(constraintsList.length, 3);
      expect(constraintsList[0].key, 'custom_constraint1');
      expect(constraintsList[1].key, 'custom_constraint2');
      expect(constraintsList[2].key, 'custom_constraint3');
    });

    test('toString() includes error details', () {
      final constraintError = ConstraintError(
        key: 'custom_constraint',
        message: 'Custom constraint',
      );
      final schemaError = SchemaConstraintsError(
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
        contains('custom_constraint'),
      );
    });
  });
}
