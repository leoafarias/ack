import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('$ValidatorError', () {
    test('toMap() returns correct structure', () {
      final error = ValidatorError(
        key: 'test_constraint',
        message: 'Test constraint failed',
        variables: {'key': 'value'},
      );

      final map = error.toMap();

      expect(map, {
        'message': 'Test constraint failed',
        'key': 'test_constraint',
        'variables': {'key': 'value'},
      });
    });

    test('toString() returns formatted string', () {
      final error = ValidatorError(
        key: 'test_constraint',
        message: 'Test constraint failed',
        variables: {'key': 'value'},
      );

      final errorString = error.toString();

      expect(
        errorString,
        contains('$ValidatorError'),
      );
      expect(
        errorString,
        contains('test_constraint'),
      );
    });
  });
}
