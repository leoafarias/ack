import 'package:ack/ack.dart';
import 'package:test/test.dart';

SchemaError _singleNestedError(SchemaResult<Object> result) {
  final error = result.getError();
  expect(error, isA<SchemaNestedError>());
  return (error as SchemaNestedError).errors.single;
}

void main() {
  group('MapSchema', () {
    test('parses string-keyed maps whose values match the value schema', () {
      final schema = Ack.map(Ack.integer());

      expect(schema.parse({'a': 1, 'b': 2}), {'a': 1, 'b': 2});
      expect(schema.parse(<String, Object?>{}), isEmpty);
      expect(schema.parse(<dynamic, dynamic>{'a': 1}), {'a': 1});
    });

    test('reports invalid values at their key path', () {
      final schema = Ack.map(Ack.integer());

      final error = _singleNestedError(schema.safeParse({'a': 1, 'b': 'two'}));

      expect(error.context.path, '#/b');
    });

    test('rejects null, non-map input, and non-string keys', () {
      final schema = Ack.map(Ack.string());

      expect(schema.safeParse(null).isFail, isTrue);
      expect(schema.safeParse(['a']).isFail, isTrue);
      expect(schema.safeParse({1: 'one'}).isFail, isTrue);
      expect(schema.nullable().safeParse(null).getOrThrow(), isNull);
    });

    test('rejects null values unless the value schema is nullable', () {
      final error = _singleNestedError(
        Ack.map(Ack.any()).safeParse({'a': null}),
      );

      expect(error.context.path, '#/a');
      expect(Ack.map(Ack.any().nullable()).parse({'a': null}), {'a': null});
    });

    test('Ack.any values accept JSON trees and reject non-JSON values', () {
      final schema = Ack.map(Ack.any().nullable());
      final value = {
        'nested': [
          null,
          1,
          {'ok': true},
        ],
      };

      expect(schema.parse(value), value);
      expect(schema.encode(value), value);
      expect(schema.safeParse({'at': DateTime(2026)}).isFail, isTrue);
      expect(
        schema.safeParse({
          'nested': {'at': DateTime(2026)},
        }).isFail,
        isTrue,
      );
      expect(schema.safeEncode({'at': DateTime(2026)}).isFail, isTrue);
    });

    test('decodes and encodes value codecs', () {
      final schema = Ack.map(Ack.date());

      final parsed = schema.parse({'start': '2026-01-02'})!;

      expect(parsed['start'], DateTime(2026, 1, 2));
      expect(schema.encode(parsed), {'start': '2026-01-02'});
    });

    test('encodes null values only when the value schema accepts null', () {
      expect(Ack.map(Ack.string().nullable()).encode({'a': null}), {'a': null});

      final result = Ack.map(Ack.string()).safeEncode({'a': null});

      expect(result.getError(), isA<SchemaNestedError>());
      final error = (result.getError() as SchemaNestedError).errors.single;
      expect(error, isA<SchemaEncodeError>());
      expect(error.context.path, '#/a');
    });

    test('returns unmodifiable parsed and encoded maps', () {
      final schema = Ack.map(Ack.string());

      final parsed = schema.parse({'a': 'x'})!;
      final encoded = schema.encode({'a': 'x'})!;

      expect(() => parsed['b'] = 'y', throwsUnsupportedError);
      expect(() => encoded['b'] = 'y', throwsUnsupportedError);
    });

    test('composes as an optional or nullable object property', () {
      final schema = Ack.object({
        'scores': Ack.map(Ack.integer()),
        'meta': Ack.map(Ack.any().nullable()).optional().nullable(),
      });

      expect(
        schema.parse({
          'scores': {'a': 1},
        }),
        {
          'scores': {'a': 1},
        },
      );
      expect(schema.parse({'scores': <String, Object?>{}, 'meta': null}), {
        'scores': <String, Object?>{},
        'meta': null,
      });

      final scoresError = _singleNestedError(
        schema.safeParse({
          'scores': {'a': 'x'},
        }),
      );
      expect(scoresError, isA<SchemaNestedError>());
      expect(
        (scoresError as SchemaNestedError).errors.single.context.path,
        '#/scores/a',
      );
    });

    test('applies refinements to the whole map', () {
      final schema = Ack.map(
        Ack.string(),
      ).refine((map) => map.length <= 1, message: 'At most one entry.');

      expect(schema.safeParse({'a': 'x'}).isOk, isTrue);
      expect(schema.safeParse({'a': 'x', 'b': 'y'}).isFail, isTrue);
    });

    test('supports equality and copyWith', () {
      expect(Ack.map(Ack.string()), Ack.map(Ack.string()));
      expect(Ack.map(Ack.string()).hashCode, Ack.map(Ack.string()).hashCode);
      expect(Ack.map(Ack.string()), isNot(Ack.map(Ack.string().nullable())));
      expect(Ack.map(Ack.string()), isNot(Ack.map(Ack.string()).nullable()));

      final copied = Ack.map(
        Ack.string(),
      ).describe('Labels').copyWith(description: 'Tags');

      expect(copied.description, 'Tags');
      expect(copied.valueSchema, Ack.string());
    });

    test('exports additionalProperties with the value schema', () {
      expect(Ack.map(Ack.string()).toJsonSchema(), {
        'type': 'object',
        'additionalProperties': {'type': 'string'},
      });
      expect(
        Ack.map(Ack.integer()).describe('Scores').toSchemaModel(),
        isA<AckObjectSchemaModel>().having(
          (model) => model.additionalProperties,
          'additionalProperties',
          isA<AckAdditionalPropertiesSchema>(),
        ),
      );
    });
  });
}
