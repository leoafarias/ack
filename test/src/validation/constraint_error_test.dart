import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('ConstraintError', () {
    test('toMap() returns correct structure', () {
      final error = ConstraintError(
        name: 'test_constraint',
        message: 'Test constraint failed',
        context: {'key': 'value'},
      );

      final map = error.toMap();

      expect(map, {
        'type': 'constraint',
        'message': 'Test constraint failed',
        'context': {'key': 'value'},
        'name': 'test_constraint',
      });
    });

    test('toString() returns formatted string', () {
      final error = ConstraintError(
        name: 'test_constraint',
        message: 'Test constraint failed',
        context: {},
      );

      expect(
        error.toString(),
        contains('SchemaError:'),
      );
      expect(
        error.toString(),
        contains('test_constraint'),
      );
    });
  });
}
