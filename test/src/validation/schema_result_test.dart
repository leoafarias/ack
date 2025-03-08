import 'package:ack/ack.dart';
import 'package:ack/src/context.dart';
import 'package:test/test.dart';

class _MockContext extends SchemaContext {
  _MockContext()
      : super(
          name: 'mock_context',
          schema: StringSchema(),
          value: 'mock_value',
          extra: {},
        );
}

void main() {
  late _MockContext mockContext;

  setUp(() {
    mockContext = _MockContext();
  });

  group('SchemaResult', () {
    test('Ok result provides correct value access', () {
      final result = mockContext.ok('test');
      expect(result.isOk, isTrue);
      expect(result.isFail, isFalse);

      result.match(
        onOk: (value) => expect(value, 'test'),
        onFail: (_) => fail('Should not fail'),
      );

      expect(result.getOrNull(), 'test');
      expect(result.getOrElse(() => 'default'), 'test');
      expect(result.getOrThrow(), 'test');

      var okCalled = false;
      result.onOk((_) => okCalled = true);
      expect(okCalled, isTrue);

      result.onFail((_) => fail('Should not call onFail'));
    });

    test('Ok result with null value', () {
      final result = mockContext.unit();
      expect(result.getOrNull(), isNull);
      expect(result.getOrElse(() => 'default'), 'default');
      expect(() => result.getOrThrow(), throwsA(isA<AckViolationException>()));
    });

    test('Fail result provides error access', () {
      final schemaError = SchemaConstraintViolation(
        constraints: [NonNullableViolation()],
        context: _MockContext(),
      );
      final result = mockContext.fail(schemaError);

      expect(result.isOk, isFalse);
      expect(result.isFail, isTrue);

      result.match(
        onOk: (_) => fail('Should not succeed'),
        onFail: (error) => expect(error, schemaError),
      );

      expect(result.getViolation(), schemaError);
      expect(result.getOrNull(), isNull);
      expect(result.getOrElse(() => 'default'), 'default');
      expect(() => result.getOrThrow(), throwsA(isA<AckViolationException>()));

      var failCalled = false;
      result.onFail((_) => failCalled = true);
      expect(failCalled, isTrue);

      result.onOk((_) => fail('Should not call onOk'));
    });

    test('getErrors throws on Ok result', () {
      final result = mockContext.ok('test');
      expect(() => result.getViolation(), throwsA(isA<ExceptionViolation>()));
    });
  });
}
