import 'package:ack/src/helpers.dart';

abstract class AckValidationError {
  final String key;

  final Map<String, Object?> context;

  final String _message;

  const AckValidationError({
    required this.key,
    required this.context,
    String? message,
  }) : _message = message ?? '';

  String get message => _renderErrorMessage(_message, context);

  String renderMessage(VariableRender variableRender) {
    return _renderErrorMessage(
      _message,
      context,
      onVariableRender: variableRender,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'key': key,
      'message': message,
      if (context.isNotEmpty) 'context': context,
    };
  }

  String toJson() => prettyJson(toMap());

  @override
  String toString() => '$runtimeType: ${toJson()}';
}

sealed class SchemaError extends AckValidationError {
  const SchemaError({
    super.context = const {},
    required super.key,
    required super.message,
  });
}

final class SchemaConstraintsError extends SchemaError {
  final List<ConstraintError> constraints;
  SchemaConstraintsError({required this.constraints})
      : super(
          key: 'constraints',
          message: 'Schema Constraints Validation failed',
        );

  factory SchemaConstraintsError.single(ConstraintError error) {
    return SchemaConstraintsError.multiple([error]);
  }

  factory SchemaConstraintsError.multiple(List<ConstraintError> errors) {
    return SchemaConstraintsError(constraints: errors);
  }

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
          context: {
            'error': error?.toString(),
            'stack_trace': stackTrace?.toString(),
          },
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
          context: {
            'value_type': valueType.toString(),
            'expected_type': expectedType.toString(),
          },
        );
}

final class InvalidJsonFormatContraintError extends SchemaError {
  final String json;
  InvalidJsonFormatContraintError({required this.json})
      : super(
          key: 'invalid_json_format',
          message: 'Invalid JSON format: $json',
          context: {'json': json},
        );
}

final class NonNullableValueConstraintError extends ConstraintError {
  NonNullableValueConstraintError()
      : super(
          key: 'non_nullable_value',
          message: 'Non nullable value is null',
          context: {},
        );
}

final class DiscriminatedSchemaError extends SchemaError {
  final String discriminator;
  final SchemaError error;
  DiscriminatedSchemaError({
    required this.discriminator,
    required this.error,
  }) : super(
          key: 'discriminated_schema',
          message: 'Discriminated Schema Validation failed',
          context: {'discriminator': discriminator, 'error': error.toMap()},
        );
}

final class ObjectSchemaPropertiesError extends SchemaError {
  final Map<String, SchemaError> errors;
  ObjectSchemaPropertiesError({required this.errors})
      : super(
          key: 'object_schema',
          message: 'Object Schema Property Validation failed',
          context: {
            'errors': {
              for (final entry in errors.entries)
                entry.key: entry.value.toMap(),
            },
          },
        );
}

final class ListSchemaItemsError extends SchemaError {
  final Map<int, SchemaError> errors;
  ListSchemaItemsError({required this.errors})
      : super(
          key: 'list_schema',
          message: 'List Schema items Validation failed',
          context: {
            'errors': {
              for (final entry in errors.entries)
                entry.key: entry.value.toMap(),
            },
          },
        );
}

final class ConstraintError extends AckValidationError {
  const ConstraintError({
    required super.key,
    required super.message,
    required super.context,
  });
}

typedef VariableRender = String Function(String key, Object value);

String _renderErrorMessage(
  String message,
  Map<String, Object?> context, {
  VariableRender? onVariableRender,
}) {
  return message.replaceAllMapped(RegExp(r'{{\s*(\w+)\s*}}'), (match) {
    final key = match.group(1);
    final value = context[key] ?? '';
    if (onVariableRender != null) {
      return onVariableRender(key!, value);
    }

    return value.toString();
  });
}
