import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('ConstraintViolation', () {
    test('toMap() returns correct structure', () {
      final error = ConstraintViolation(
        constraintName: 'test_constraint',
        message: 'Test constraint failed',
        variables: {'key': 'value'},
      );

      final map = error.toMap();

      expect(map, {
        'message': 'Test constraint failed',
        'constraintName': 'test_constraint',
        'variables': {'key': 'value'},
      });
    });

    test('toString() returns formatted string', () {
      final error = ConstraintViolation(
        constraintName: 'test_constraint',
        message: 'Test constraint failed',
        variables: {'key': 'value'},
      );

      final errorString = error.toString();

      expect(
        errorString,
        contains('ConstraintViolation:'),
      );
      expect(
        errorString,
        contains('test_constraint'),
      );
    });
  });
}
