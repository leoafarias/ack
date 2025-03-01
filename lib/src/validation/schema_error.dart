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

  static PathSchemaError _pathSchema({
    required String path,
    required String message,
    required List<SchemaError> errors,
    required Schema schema,
  }) {
    return PathSchemaError(
      path: path,
      schema: schema,
      message: message,
      errors: errors,
    );
  }

  static List<SchemaError> pathSchemas({
    required String path,
    required String message,
    required List<SchemaError> errors,
    required Schema schema,
  }) {
    List<SchemaError> schemaErrors = [];

    for (final error in errors) {
      if (error is PathSchemaError) {
        schemaErrors.add(error.withRootPath(path));
      } else {
        schemaErrors.add(
          _pathSchema(
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

  String get message => _message;

  Map<String, Object?> toMap() {
    return {
      'type': type,
      'message': _message,
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

final class PathSchemaError extends SchemaError {
  static const String key = 'path_schema_error';
  final Schema schema;
  final String path;
  final List<SchemaError> errors;
  PathSchemaError({
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

  PathSchemaError withRootPath(String rootKey) {
    return PathSchemaError(
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
  }) : super(type: 'constraint_$name');
}
