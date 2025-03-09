import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../../test_helpers.dart';

void main() {
  group('Number Validators', () {
    group('MinValueValidator', () {
      test('Values above min pass validation', () {
        final validator = NumberMinConstraint(5);
        expect(validator.isValid(6), isTrue);
        expect(validator.isValid(5), isTrue);
      });

      test('Values below min fail validation', () {
        final validator = NumberMinConstraint(5);
        expect(validator.isValid(4), isFalse);
      });

      test('schema validation works with min value', () {
        final schema = DoubleSchema().max(5);
        expect(schema.validate(4).isOk, isTrue);

        final result = schema.validate(6);
        expect(result.isFail, isTrue);
        expect(result, hasOneConstraintViolation('number_max'));
      });
    });

    group('MaxValueValidator', () {
      test('Values below max pass validation', () {
        final validator = NumberMaxConstraint(5);
        expect(validator.isValid(4), isTrue);
        expect(validator.isValid(5), isTrue);
      });

      test('Values above max fail validation', () {
        final validator = NumberMaxConstraint(5);
        expect(validator.isValid(6), isFalse);
      });
    });

    group('RangeValidator', () {
      test('Values in range pass validation', () {
        final validator = NumberRangeValidator(1, 5);
        expect(validator.isValid(1), isTrue);
        expect(validator.isValid(3), isTrue);
        expect(validator.isValid(5), isTrue);
      });

      test('Values outside range fail validation', () {
        final validator = NumberRangeValidator(1, 5);
        expect(validator.isValid(0), isFalse);
        expect(validator.isValid(6), isFalse);
        expect(validator.isValid(1), isTrue);
        expect(validator.isValid(5), isTrue);
      });

      test('schema validation works with range', () {
        final schema = DoubleSchema().range(1, 5);
        final result = schema.validate(3);
        expect(result.isOk, isTrue);

        final result2 = schema.validate(6);
        expect(result2, hasOneConstraintViolation('number_range'));
      });
    });
  });
}
