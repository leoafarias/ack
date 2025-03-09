import 'package:ack/src/helpers.dart';
import 'package:meta/meta.dart';

import '../constraints/constraint.dart';
import '../constraints/validators.dart';
import '../context.dart';
import '../schemas/schema.dart';

/// A mixin that provides common functionality for all types of errors.
mixin ErrorBase {
  /// The unique identifier for this error type.
  String get key;

  String get message;

  @override
  String toString() => '$runtimeType: $key: $message';

  Map<String, Object?> toMap();
}

sealed class SchemaError extends SchemaContext with ErrorBase {
  @override
  final String key;

  @override
  final String message;

  SchemaError({
    required super.name,
    required super.schema,
    required super.value,
    required this.message,
    required this.key,
  });

  @override
  Map<String, Object?> toMap() {
    return {'schema': schema.toMap(), 'value': value, 'name': name};
  }

  @override
  String toString() =>
      '$runtimeType: name: $key, alias: $name, schema: ${schema.runtimeType}, value: ${value ?? 'N/A'}, message: $message';
}

final class SchemaUnknownError extends SchemaError {
  final Object error;
  final StackTrace stackTrace;
  SchemaUnknownError({
    required this.error,
    required this.stackTrace,
    required SchemaContext context,
  }) : super(
          key: 'unknown',
          name: context.name,
          schema: context.schema,
          value: context.value,
          message: 'Unknown schema error: $error \n$stackTrace',
        );

  @override
  String toString() => '$error \n$stackTrace';
}

final class SchemaConstraintsError extends SchemaError {
  final List<ConstraintError> constraints;
  SchemaConstraintsError({
    required this.constraints,
    required SchemaContext context,
  }) : super(
          key: 'constraints',
          name: context.name,
          schema: context.schema,
          value: context.value,
          message: constraints.map((e) => '${e.key}: ${e.message}').join('\n'),
        );

  bool get isInvalidType => constraints.any((e) => e is InvalidTypeSchemaError);

  bool get isNonNullable => constraints.any((e) => e is NonNullableSchemaError);

  ConstraintError? getConstraint(String key) {
    return constraints.firstWhereOrNull((e) => e.key == key);
  }

  T? getConstraintByType<T extends ConstraintError>() {
    return constraints.firstWhereOrNull((e) => e is T) as T?;
  }
}

final class SchemaNestedError extends SchemaError {
  final List<SchemaError> errors;

  SchemaNestedError({required this.errors, required SchemaContext context})
      : super(
          key: 'nested',
          name: context.name,
          schema: context.schema,
          value: context.value,
          message: errors.map((e) => '${e.name}: ${e.message}').join('\n'),
        ) {
    assert(schema is ObjectSchema || schema is ListSchema,
        'NestedSchemaError must be used with ObjectSchema or ListSchema');
  }
}

@visibleForTesting
class SchemaMockError extends SchemaError {
  SchemaMockError({
    SchemaContext context = const SchemaMockContext(),
    super.message = 'mock_message',
  }) : super(
          key: 'mock_error',
          name: context.name,
          schema: context.schema,
          value: context.value,
        );
}
