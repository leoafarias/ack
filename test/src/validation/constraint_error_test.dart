import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('ConstraintError', () {
    test('toMap() returns correct structure', () {
      final error = ConstraintError(
        key: 'test_constraint',
        message: 'Test constraint failed',
        context: {'key': 'value'},
      );

      final map = error.toMap();

      expect(map, {
        'message': 'Test constraint failed',
        'context': {'key': 'value'},
        'key': 'test_constraint',
      });
    });

    test('toString() returns formatted string', () {
      final error = ConstraintError(
        key: 'test_constraint',
        message: 'Test constraint failed',
        context: {},
      );

      final errorString = error.toString();

      expect(
        errorString,
        contains('ConstraintError:'),
      );
      expect(
        errorString,
        contains('test_constraint'),
      );
    });
  });
}
