import 'package:ack/src/helpers.dart';

import '../context.dart';

abstract class Violation {
  final String key;

  final ViolationContext context;

  final String _message;

  const Violation({
    required this.key,
    required this.context,
    String? message,
  }) : _message = message ?? '';

  String get message => _renderErrorMessage(_message, context.toMap());

  String renderMessage(VariableRender variableRender) {
    return _renderErrorMessage(
      _message,
      context.toMap(),
      onVariableRender: variableRender,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'key': key,
      'message': message,
      if (context.isNotEmpty) 'context': context.toMap(),
    };
  }

  String toJson() => prettyJson(toMap());

  @override
  String toString() => '$runtimeType: ${toJson()}';
}

sealed class SchemaError extends Violation {
  const SchemaError({
    required super.key,
    required super.message,
    required super.context,
  });
}

final class SchemaConstraintsError extends SchemaError {
  final List<ConstraintError> constraints;
  SchemaConstraintsError({
    required this.constraints,
    required super.context,
  }) : super(
          key: 'constraints',
          message: 'Schema Constraints Validation failed',
        );

  SchemaConstraintsError.single(
    ConstraintError error, {
    Map<String, Object?>? extra,
  }) : this.multiple([error], extra: extra);

  SchemaConstraintsError.multiple(
    List<ConstraintError> errors, {
    Map<String, Object?>? extra,
  }) : this(constraints: errors, context: ViolationContext.getWithExtras({}));
  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      'constraints': constraints.map((e) => e.toMap()).toList(),
    };
  }
}

final class UnknownExceptionSchemaError extends SchemaError {
  final Object? error;
  final StackTrace? stackTrace;
  UnknownExceptionSchemaError({this.error, this.stackTrace})
      : super(
          key: 'unknown_exception',
          message: 'Unknown Exception when validating schema {{ error }}',
          context: ViolationContext.getWithExtras({
            'error': error?.toString(),
            'stack_trace': stackTrace?.toString(),
          }),
        );
}

final class InvalidTypeConstraintError extends ConstraintError {
  final Type valueType;
  final Type expectedType;
  InvalidTypeConstraintError({
    required this.valueType,
    required this.expectedType,
  }) : super(
          key: 'invalid_type',
          message: 'Invalid type of $valueType, expected $expectedType',
          context: ViolationContext.getWithExtras({
            'value_type': valueType.toString(),
            'expected_type': expectedType.toString(),
          }),
        );
}

final class InvalidJsonFormatContraintError extends SchemaError {
  final String json;
  InvalidJsonFormatContraintError({required this.json})
      : super(
          key: 'invalid_json_format',
          message: 'Invalid JSON format: {{ json }}',
          context: ViolationContext.getWithExtras({'json': json}),
        );
}

final class NonNullableValueConstraintError extends ConstraintError {
  NonNullableValueConstraintError()
      : super(
          key: 'non_nullable_value',
          message: 'Non nullable value is null',
          context: ViolationContext.getWithExtras({}),
        );
}

@Deprecated('Use ObjectSchemaError instead')
final class DiscriminatedSchemaError extends SchemaError {
  final String discriminator;

  final SchemaError error;
  DiscriminatedSchemaError({
    required this.discriminator,
    required this.error,
  }) : super(
          key: 'discriminated',
          message: 'Discriminated schema validation failed',
          context: ViolationContext.getWithExtras({
            'discriminator': discriminator,
            'error': error.toMap(),
          }),
        );
}

final class ObjectSchemaError extends SchemaError {
  final Map<String, SchemaError> errors;

  ObjectSchemaError({required this.errors})
      : super(
          key: 'object',
          message: 'Object schema validation failed',
          context: ViolationContext.getWithExtras({
            'errors': {
              for (final entry in errors.entries)
                entry.key: entry.value.toMap(),
            },
          }),
        );

  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      'errors': {
        for (final entry in errors.entries) entry.key: entry.value.toMap(),
      },
    };
  }
}

final class ListSchemaError extends SchemaError {
  final Map<int, SchemaError> errors;

  ListSchemaError({required this.errors})
      : super(
          key: 'list',
          message: 'List schema items validation failed',
          context: ViolationContext.getWithExtras({
            'errors': {
              for (final entry in errors.entries)
                entry.key: entry.value.toMap(),
            },
          }),
        );
}

// TODO: Rename this to ConstraintViolation
final class ConstraintError extends Violation {
  const ConstraintError({
    required super.key,
    required super.message,
    required super.context,
  });
}

typedef VariableRender = String Function(String key, Object value);

String _renderErrorMessage(
  String message,
  Map<String, Object?> data, {
  VariableRender? onVariableRender,
}) {
  return message.replaceAllMapped(RegExp(r'{{\s*(\w+)\s*}}'), (match) {
    final key = match.group(1) ?? '';
    final value = data[key] ?? 'N/A';
    if (onVariableRender != null) {
      return onVariableRender(key, value);
    }

    return value.toString();
  });
}
