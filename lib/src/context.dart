import 'dart:async';

import 'package:meta/meta.dart';

import 'schemas/schema.dart';
import 'validation/schema_result.dart';

final _schemaMetadataKey = #schemaMetadata;

class ViolationContext<T extends Schema> {
  final String? name;
  final Object? value;
  final T? schema;
  Map<String, Object?> extra = {};

  ViolationContext({
    String? name,
    this.schema,
    this.value,
    Map<String, Object?>? extra,
  }) : name = name ?? schema?.runtimeType.toString() {
    if (extra != null) {
      this.extra = extra;
    }
  }

  static ViolationContext getWithExtras(Map<String, Object?> extra) {
    ViolationContext? context = maybeGetCurrentViolationContext();

    return context == null
        ? ViolationContext(extra: extra)
        : context.mergeExtras(extra);
  }

  bool get isNotEmpty => toMap().isNotEmpty;

  ViolationContext mergeExtras(Map<String, Object?> extra) {
    return ViolationContext(
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

  Map<String, Object?> toMap() => {
        if (name != null) 'name': name,
        if (value != null) 'value': value,
        if (schema != null) 'schema': schema!.toMap(),
        if (extra.isNotEmpty) 'extra': extra,
      };
}

ViolationContext<T> getCurrentViolationContext<T extends Schema>() {
  try {
    return maybeGetCurrentViolationContext<T>()!;
  } catch (e) {
    Error.throwWithStackTrace(
      StateError(
        'SchemaMetadata.augment must be called within a Schema context',
      ),
      StackTrace.current,
    );
  }
}

ViolationContext<T>? maybeGetCurrentViolationContext<T extends Schema>() {
  return Zone.current[_schemaMetadataKey] as ViolationContext<T>?;
}

SchemaResult<T> executeWithContext<T extends Object>(
  ViolationContext context,
  SchemaResult<T> Function() action,
) {
  return wrapWithViolationContext(context, () => action());
}

@visibleForTesting
T wrapWithViolationContext<T>(ViolationContext context, T Function() action) {
  return Zone.current
      .fork(zoneValues: {_schemaMetadataKey: context}).run(action);
}
