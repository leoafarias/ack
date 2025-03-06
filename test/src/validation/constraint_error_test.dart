import 'package:ack/ack.dart';
import 'package:ack/src/context.dart';
import 'package:test/test.dart';

class MockContext extends ViolationContext {
  MockContext(Map<String, Object?> extra)
      : super(name: 'mock_context', schema: StringSchema(), extra: extra);
}

void main() {
  group('ConstraintError', () {
    test('toMap() returns correct structure', () {
      final mockContext = MockContext({'key': 'value'});
      final error = ConstraintError(
        key: 'test_constraint',
        message: 'Test constraint failed',
        context: mockContext,
      );

      final map = error.toMap();

      expect(map, {
        'message': 'Test constraint failed',
        'context': mockContext.toMap(),
        'key': 'test_constraint',
      });
    });

    test('toString() returns formatted string', () {
      final error = ConstraintError(
        key: 'test_constraint',
        message: 'Test constraint failed',
        context: MockContext({'key': 'value'}),
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
