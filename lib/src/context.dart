import 'dart:async';

import 'package:ack/src/schemas/schema.dart';
import 'package:ack/src/validation/schema_error.dart';
import 'package:meta/meta.dart';

import 'validation/schema_result.dart';

final kSchemaContextKey = #schemaContextKey;

class SchemaContext<T extends Object> {
  final String? name;
  final Object? value;
  final Schema schema;

  Map<String, Object?> extra = {};

  SchemaContext({
    required this.name,
    required this.schema,
    required this.value,
    Map<String, Object?>? extra,
  }) {
    if (extra != null) {
      this.extra = extra;
    }
  }

  void _assertNoReservedKeys(Map<String, Object?> extra) {
    const reservedKeys = ['value', 'schema'];
    for (final key in reservedKeys) {
      assert(
        !extra.containsKey(key),
        'extra must not contain a $key key',
      );
    }
  }

  bool get isNotEmpty => toMap().isNotEmpty;

  SchemaResult<T> ok(T value) => SchemaResult.ok(value, schema);

  SchemaResult<T> fail(SchemaViolation error) =>
      SchemaResult.fail(error, schema);

  SchemaResult<T> unit() => SchemaResult.unit(schema);

  SchemaContext mergeExtra(Map<String, Object?> extra) {
    return SchemaContext(
      name: name,
      schema: schema,
      value: value,
      extra: {...this.extra, ...extra},
    );
  }

  Object? getExtra(String key) => extra[key];

  void addExtra(MapEntry<String, Object?> entry) {
    extra.addEntries([entry]);
  }

  @override
  Map<String, Object?> toMap() => {
        if (name != null) 'name': name,
        'value': value,
        if (extra.isNotEmpty) 'extra': extra,
      };
}

SchemaResult<T> executeWithContext<T extends Object>(
  SchemaContext context,
  SchemaResult<T> Function() action,
) {
  return wrapWithViolationContext(context, () => action());
}

@visibleForTesting
T wrapWithViolationContext<T>(SchemaContext context, T Function() action) {
  return Zone.current
      .fork(zoneValues: {kSchemaContextKey: context}).run(action);
}

SchemaContext getCurrentSchemaContext() {
  try {
    return Zone.current[kSchemaContextKey] as SchemaContext;
  } catch (e) {
    Error.throwWithStackTrace(
      StateError(
        'SchemaMetadata.augment must be called within a Schema context',
      ),
      StackTrace.current,
    );
  }
}
