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

      expect(
          map,
          equals({
            'key': 'test_constraint',
            'message': 'Test constraint failed',
            'variables': {'key': 'value'},
          }));
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
