import 'package:ack/src/helpers.dart';

import '../schemas/schema.dart';

sealed class SchemaError {
  final String type;
  final Map<String, Object?> context;

  final String _message;

  const SchemaError({
    required this.type,
    required String message,
    this.context = const {},
  }) : _message = message;

  static InvalidTypeSchemaError invalidType({
    required Type valueType,
    required Type expectedType,
  }) {
    return InvalidTypeSchemaError(
      valueType: valueType,
      expectedType: expectedType,
    );
  }

  static InvalidJsonFormatSchemaError invalidJsonFormat(String json) {
    return InvalidJsonFormatSchemaError(json: json);
  }

  static NonNullableValueSchemaError nonNullableValue() {
    return NonNullableValueSchemaError();
  }

  static UnknownExceptionSchemaError unknownException({
    Object? error,
    StackTrace? stackTrace,
  }) {
    return UnknownExceptionSchemaError(error: error, stackTrace: stackTrace);
  }

  static ItemSchemaError _itemSchema({
    required String path,
    required String message,
    required List<SchemaError> errors,
    required Schema schema,
  }) {
    return ItemSchemaError(
      path: path,
      schema: schema,
      message: message,
      errors: errors,
    );
  }

  static List<SchemaError> itemSchemas({
    required String path,
    required String message,
    required List<SchemaError> errors,
    required Schema schema,
  }) {
    List<SchemaError> schemaErrors = [];

    for (final error in errors) {
      if (error is ItemSchemaError) {
        schemaErrors.add(error.withRootPath(path));
      } else {
        schemaErrors.add(
          _itemSchema(
            path: path,
            message: message,
            errors: [error],
            schema: schema,
          ),
        );
      }
    }

    return schemaErrors;
  }

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
      'type': type,
      'message': message,
      if (context.isNotEmpty) 'context': context,
    };
  }

  String toJson() => prettyJson(toMap());

  @override
  String toString() => 'SchemaError: ${toJson()}';
}

final class InvalidTypeSchemaError extends SchemaError {
  static const String key = 'invalid_type';

  final Type valueType;
  final Type expectedType;
  InvalidTypeSchemaError({
    required this.valueType,
    required this.expectedType,
  }) : super(
          type: key,
          message: 'Invalid type of $valueType, expected $expectedType',
          context: {
            'valueType': valueType.toString(),
            'expectedType': expectedType.toString(),
          },
        );
}

/// Invalid json format
///
/// This error is thrown when the value is not a valid JSON string.
final class InvalidJsonFormatSchemaError extends SchemaError {
  static const String key = 'invalid_json_format';
  final String json;
  InvalidJsonFormatSchemaError({required this.json})
      : super(
          type: key,
          message: 'Invalid JSON format: $json',
          context: {'json': json},
        );
}

final class NonNullableValueSchemaError extends SchemaError {
  static const String key = 'non_nullable_value';
  NonNullableValueSchemaError()
      : super(type: key, message: 'Non nullable value is null');
}

final class UnknownExceptionSchemaError extends SchemaError {
  static const String key = 'unknown_exception';
  final Object? error;
  final StackTrace? stackTrace;
  UnknownExceptionSchemaError({this.error, this.stackTrace})
      : super(
          type: key,
          message: 'Unknown Exception when validating schema ${error ?? ''}',
          context: {'error': error, 'stackTrace': stackTrace},
        );
}

final class ItemSchemaError extends SchemaError {
  static const String key = 'item';
  final Schema schema;
  final String path;
  final List<SchemaError> errors;
  ItemSchemaError({
    required this.path,
    required this.schema,
    required super.message,
    required this.errors,
  }) : super(
          type: key,
          context: {
            'errors': errors.map((e) => e.toMap()).toList(),
            'path': path,
          },
        );

  ItemSchemaError withRootPath(String rootKey) {
    return ItemSchemaError(
      path: '$rootKey.$path',
      schema: schema,
      message: message,
      errors: errors,
    );
  }
}

class ConstraintError extends SchemaError {
  final String name;

  const ConstraintError({
    required this.name,
    required super.message,
    required super.context,
  }) : super(type: 'constraint');

  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'name': name};
  }
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
