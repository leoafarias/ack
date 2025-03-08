import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('MinItemsListValidator', () {
    test('List with length >= min passes validation', () {
      final validator = MinItemsListValidator(3);
      expect(validator.isValid([1, 2, 3]), isTrue);
      expect(validator.isValid([1, 2, 3, 4]), isTrue);
    });

    test('List with length < min fails validation', () {
      final validator = MinItemsListValidator(3);
      expect(validator.isValid([1, 2]), isFalse);
    });

    test('schema validation works with minItems', () {
      final schema = ListSchema(IntegerSchema()).minItems(3);
      expect(schema.validate([1, 2, 3]).isOk, isTrue);

      final result = schema.validate([1, 2]);
      expect(result.isFail, isTrue);

      final error = (result as Fail).error;
      expect(error, isA<SchemaConstraintViolation>());

      final constraintsError = error as SchemaConstraintViolation;
      expect(
        constraintsError.constraints.any((e) => e.key == 'min_items'),
        isTrue,
      );
    });

    // Test error message
    test('error message is correct', () {
      final validator = MinItemsListValidator(3);
      final error = validator.buildError([1, 2]);
      expect(error.message, 'Too few items: 2. Min: 3');
    });
  });
}
