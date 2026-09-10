import 'package:ack/ack.dart';
import 'package:ack_mcp_dart/ack_mcp_dart.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:test/test.dart';

import 'support/fixtures.dart';

void main() {
  test('applies defaults and normalizes integral doubles', () {
    final schema = searchSchema();
    expect(parseMcpToolArguments(schema, {'query': 'dart'}).getOrThrow(), {
      'query': 'dart',
      'limit': 5,
    });
    final parsed = parseMcpToolArguments(schema, {
      'query': 'dart',
      'limit': 2.0,
    }).getOrThrow()!;
    expect(parsed['limit'], isA<int>().having((v) => v, 'value', 2));
    expect(
      parseMcpToolArguments(schema, {'query': 'dart', 'limit': 2.5}).isFail,
      isTrue,
    );
  });

  test('decodes a datetime without changing its wire schema', () {
    final schema = Ack.object({'at': Ack.datetime()});
    final wire = schema.toJsonSchema();
    final parsed = parseMcpToolArguments(schema, {
      'at': '2026-09-10T12:00:00Z',
    }).getOrThrow()!;
    expect(parsed['at'], DateTime.utc(2026, 9, 10, 12));
    expect(schema.toJsonSchema(), wire);
  });

  test('model adapter receives the validated runtime defaults', () {
    final result = searchModel.safeParse({'query': 'dart'}).getOrThrow()!;
    expect(result.query, 'dart');
    expect(result.limit, 5);
  });

  test('flattens nested refinement and list failures to leaf paths', () {
    final schema = Ack.object({
      'items': Ack.list(
        Ack.object({
          'value': Ack.string().refine((v) => v == 'ok', message: 'Must be ok'),
        }),
      ),
    });
    final error = parseMcpToolArguments(schema, {
      'items': [
        {'value': 'secret-value'},
      ],
    }, debugName: 'search').getError();
    expect(error.name, 'search');
    final lines = describeAckValidationError(error);
    expect(lines, hasLength(1));
    expect(lines.single, contains('#/items/0/value: '));
    expect(lines.single, contains('Must be ok'));
    final result = ackValidationErrorToCallToolResult(
      error,
      toolName: 'search',
    );
    expect(result.isError, isTrue);
    final text = (result.content.single as TextContent).text;
    expect(text, startsWith("Invalid arguments for tool 'search':"));
    expect(text, contains(lines.single));
    expect(text, isNot(contains('secret-value')));
    expect(text, isNot(contains('StackTrace')));
  });

  test('never includes cause, stack trace or context value', () {
    final error = SchemaValidationError(
      message: 'Invalid input',
      context: SchemaContext(
        name: 'input',
        schema: Ack.object({}),
        value: 'secret-value',
      ),
      cause: 'secret-cause',
      stackTrace: StackTrace.fromString('secret-stack'),
    );
    expect(describeAckValidationError(error), [
      '#: Argument validation failed.',
    ]);
    expect(
      (ackValidationErrorToCallToolResult(error, toolName: 'x').content.single
              as TextContent)
          .text,
      "Invalid arguments for tool 'x':\n#: Argument validation failed.",
    );
  });

  for (final input in [
    Ack.object({
      'token': Ack.string().refine(
        (value) => int.parse(value) > 0,
        message: 'Must be positive',
      ),
    }),
    Ack.object({'token': Ack.string().transform(int.parse)}),
  ]) {
    test('exception-backed failures do not expose exception text or input', () {
      final error = parseMcpToolArguments(input, {
        'token': 'PRIVATE-TOKEN-123',
      }).getError();
      final lines = describeAckValidationError(error);
      expect(lines, ['#/token: Argument validation failed.']);
      final result = ackValidationErrorToCallToolResult(
        error,
        toolName: 'search',
      );
      final text = (result.content.single as TextContent).text;
      expect(text, isNot(contains('PRIVATE-TOKEN-123')));
      expect(text, isNot(contains('FormatException')));
    });
  }

  test('empty nested error falls back to its own message', () {
    final error = SchemaNestedError(
      errors: [],
      context: SchemaContext(name: 'input', schema: Ack.object({}), value: {}),
    );
    expect(describeAckValidationError(error), ['#: ${error.message}']);
  });
}
