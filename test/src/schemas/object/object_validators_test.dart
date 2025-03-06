import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('PropertyRequiredConstraintError', () {
    test('validates required property correctly', () {
      final validator =
          PropertyRequiredConstraintError('name', ['name', 'age']);

      expect(
        validator.isValid({'name': 'John', 'age': 25}),
        isTrue,
        reason: 'Should be valid when required property exists',
      );

      expect(
        validator.isValid({'age': 25}),
        isFalse,
        reason: 'Should be invalid when required property is missing',
      );

      expect(
        validator.isValid({'email': 'test@test.com'}),
        isFalse,
        reason: 'Should be invalid when required property is missing',
      );
    });

    test('handles empty required keys list', () {
      final validator = PropertyRequiredConstraintError('name', []);

      expect(
        validator.isValid({'email': 'test@test.com'}),
        isTrue,
        reason: 'Should be valid when required keys list is empty',
      );
    });

    test('handles single required key', () {
      final validator = PropertyRequiredConstraintError('name', ['name']);

      expect(
        validator.isValid({'name': 'John'}),
        isTrue,
        reason: 'Should be valid when single required property exists',
      );

      expect(
        validator.isValid({'age': 25}),
        isFalse,
        reason: 'Should be invalid when single required property is missing',
      );
    });

    test('validates null values correctly', () {
      final validator = PropertyRequiredConstraintError('name', ['name']);

      expect(
        validator.isValid({'name': null}),
        isTrue,
        reason: 'Should be valid when required property exists with null value',
      );
    });
  });
}
