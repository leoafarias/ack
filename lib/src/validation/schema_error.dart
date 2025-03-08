import 'package:ack/src/helpers.dart';

import '../context.dart';

abstract class AckViolation {
  final String key;

  final ViolationContext context;

  final String _message;

  const AckViolation({
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

sealed class SchemaViolation extends AckViolation {
  const SchemaViolation({
    required super.key,
    required super.message,
    required super.context,
  });
}

final class SchemaConstraintViolation extends SchemaViolation {
  final List<ConstraintViolation> constraints;
  SchemaConstraintViolation({
    required this.constraints,
    required super.context,
  }) : super(
          key: 'constraints',
          message: 'Schema Constraints Validation failed',
        );

  SchemaConstraintViolation.single(
    ConstraintViolation error, {
    Map<String, Object?>? extra,
    required ViolationContext context,
  }) : this.multiple([error], extra: extra, context: context);

  SchemaConstraintViolation.multiple(
    List<ConstraintViolation> errors, {
    Map<String, Object?>? extra,
    required ViolationContext context,
  }) : this(constraints: errors, context: context.mergeExtras(extra ?? {}));
  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      'constraints': constraints.map((e) => e.toMap()).toList(),
    };
  }
}

final class UnknownSchemaViolation extends SchemaViolation {
  final Object? error;
  final StackTrace? stackTrace;
  UnknownSchemaViolation({
    this.error,
    this.stackTrace,
    required ViolationContext context,
  }) : super(
          key: 'unknown_exception',
          message: 'Unknown Exception when validating schema {{ error }}',
          context: context.mergeExtras({
            'error': error?.toString(),
            'stack_trace': stackTrace?.toString(),
          }),
        );
}

final class InvalidTypeConstraintError extends ConstraintViolation {
  final Type valueType;
  final Type expectedType;
  InvalidTypeConstraintError({
    required this.valueType,
    required this.expectedType,
    required ViolationContext context,
  }) : super(
          key: 'invalid_type',
          message: 'Invalid type of $valueType, expected $expectedType',
          context: context.mergeExtras({
            'value_type': valueType.toString(),
            'expected_type': expectedType.toString(),
          }),
        );
}

final class NonNullableValueConstraintError extends ConstraintViolation {
  NonNullableValueConstraintError({required ViolationContext context})
      : super(
          key: 'non_nullable_value',
          message: 'Non nullable value is null',
          context: context.mergeExtras({}),
        );
}

@Deprecated('Use ObjectSchemaError instead')
final class DiscriminatedSchemaViolation extends SchemaViolation {
  final String discriminator;

  final SchemaViolation error;
  @override
  final ViolationContext context;
  DiscriminatedSchemaViolation({
    required this.discriminator,
    required this.error,
    required this.context,
  }) : super(
          key: 'discriminated',
          message: 'Discriminated schema validation failed',
          context: context.mergeExtras({
            'discriminator': discriminator,
            'error': error.toMap(),
          }),
        );
}

final class ObjectSchemaViolation extends SchemaViolation {
  final Map<String, SchemaViolation> errors;

  ObjectSchemaViolation({
    required this.errors,
    required ViolationContext context,
  }) : super(
          key: 'object',
          message: 'Object schema validation failed',
          context: context.mergeExtras({
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

final class ListSchemaViolation extends SchemaViolation {
  final Map<int, SchemaViolation> errors;

  ListSchemaViolation({required this.errors, required ViolationContext context})
      : super(
          key: 'list',
          message: 'List schema items validation failed',
          context: context.mergeExtras({
            'errors': {
              for (final entry in errors.entries)
                entry.key: entry.value.toMap(),
            },
          }),
        );
}

final class ConstraintViolation extends AckViolation {
  const ConstraintViolation({
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
