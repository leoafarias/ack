import 'package:ack/ack.dart';
import 'package:ack/src/context.dart';
import 'package:test/test.dart';

class _MockContext extends SchemaContext {
  _MockContext(Map<String, Object?> extra)
      : super(
          name: 'mock_context',
          schema: StringSchema(),
          value: 'mock_value',
          extra: extra,
        );
}

void main() {
  group('ConstraintViolation', () {
    test('toMap() returns correct structure', () {
      final mockContext = _MockContext({'key': 'value'});
      final error = ConstraintViolation(
        key: 'test_constraint',
        message: 'Test constraint failed',
        extra: {'key': 'value'},
      );

      final map = error.toMap();

      expect(map, {
        'message': 'Test constraint failed',
        'context': mockContext.toMap(),
        'key': 'test_constraint',
      });
    });

    test('toString() returns formatted string', () {
      final error = ConstraintViolation(
        key: 'test_constraint',
        message: 'Test constraint failed',
        extra: {'key': 'value'},
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
