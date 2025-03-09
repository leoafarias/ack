import 'package:ack/src/helpers.dart';
import 'package:meta/meta.dart';

import '../context.dart';
import '../schemas/schema.dart';

/// A mixin that provides common functionality for all types of errors.
mixin ErrorBase {
  /// The unique identifier for this error type.
  String get key;

  String get message;

  @override
  String toString() => '$runtimeType: $key: $message';
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

  Map<String, Object?> toMap() {
    return {'schema': schema.toMap(), 'value': value, 'name': name};
  }

  @override
  String toString() =>
      '$runtimeType: name: $key, alias: $name, schema: ${schema.runtimeType}, value: ${value ?? 'N/A'}, message: $message';
}

final class UnknownSchemaError extends SchemaError {
  final Object error;
  final StackTrace stackTrace;
  UnknownSchemaError({
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

final class SchemaConstraintError extends SchemaError {
  final List<ConstraintError> validations;
  SchemaConstraintError({
    required this.validations,
    required SchemaContext context,
  }) : super(
          key: 'constraints',
          name: context.name,
          schema: context.schema,
          value: context.value,
          message: '''
{{#each validations}}
{{message}}
{{/each}}
''',
        );

  bool get isInvalidType => validations.any((e) => e is InvalidTypeSchemaError);

  bool get isNonNullable => validations.any((e) => e is NonNullableSchemaError);

  ConstraintError? getConstraint<T extends ConstraintError>() {
    return validations.firstWhereOrNull((e) => e is T);
  }
}

final class NestedSchemaError extends SchemaError {
  final List<SchemaError> errors;

  NestedSchemaError({required this.errors, required SchemaContext context})
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

final class InvalidTypeSchemaError extends ConstraintError {
  final Type valueType;
  final Type expectedType;
  InvalidTypeSchemaError({
    required this.valueType,
    required this.expectedType,
  }) : super(
          key: 'invalid_type',
          message: 'Invalid type of $valueType, expected $expectedType',
        );
}

final class NonNullableSchemaError extends ConstraintError {
  NonNullableSchemaError()
      : super(key: 'non_nullable', message: 'Value cannot be null');
}

final class ConstraintError with ErrorBase {
  @override
  final String key;

  @override
  final String message;

  ConstraintError({required this.key, required this.message});
}

@visibleForTesting
class MockSchemaError extends SchemaError {
  MockSchemaError({
    SchemaContext context = const MockContext(),
    super.message = 'mock_message',
  }) : super(
          key: 'mock_error',
          name: context.name,
          schema: context.schema,
          value: context.value,
        );
}

class MockContext extends SchemaContext {
  const MockContext()
      : super(
          name: 'mock_context',
          schema: const StringSchema(),
          value: 'mock_value',
        );
}
