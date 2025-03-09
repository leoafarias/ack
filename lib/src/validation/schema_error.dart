import 'package:ack/src/helpers.dart';
import 'package:ack/src/helpers/template.dart';
import 'package:meta/meta.dart';

import '../context.dart';
import '../schemas/schema.dart';

/// A mixin that provides common functionality for all types of errors.
mixin ErrorBase {
  /// The unique identifier for this error type.
  String get key;

  /// Variables used to render the message template.
  Map<String, Object?>? get variables;

  /// The message template.
  String get template;

  /// Renders the message with all variables.
  String get message => render();

  late final render = Template(template, data: variables).render;

  /// Converts the error to a map representation.
  Map<String, Object?> toMap() {
    final map = <String, Object?>{'key': key, 'message': message};

    final vars = variables;
    if (vars != null && vars.isNotEmpty) {
      map['variables'] = vars;
    }

    return map;
  }

  /// Retrieves a variable by key with type checking.
  T getVariable<T>(String key) {
    final value = variables?[key];
    if (value == null) {
      throw ArgumentError('Variable $key not found');
    }

    return value as T;
  }

  @override
  String toString() => '$runtimeType: $key: $message';
}

sealed class SchemaError extends SchemaContext with ErrorBase {
  @override
  final String key;

  @override
  final Map<String, Object?> variables;

  @override
  late final String template;

  SchemaError({
    required super.name,
    required super.schema,
    required super.value,
    required String message,
    required this.key,
    this.variables = const {},
  }) : template = message;

  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      'schema': schema.toMap(),
      'value': value,
      'name': name,
    };
  }

  @override
  String toString() =>
      '$runtimeType: name: $key, alias: $name, schema: ${schema.runtimeType}, value: ${value ?? 'N/A'}, message: $message, variables: $variables';
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
          message: 'Unknown schema error: {{error}} \n{{stackTrace}}',
          variables: {
            'error': error.toString(),
            'stackTrace': stackTrace.toString(),
          },
        );

  @override
  String toString() => '$error \n$stackTrace';
}

final class InvalidTypeSchemaError extends SchemaError {
  final Type valueType;
  final Type expectedType;
  InvalidTypeSchemaError({
    required this.valueType,
    required this.expectedType,
    required SchemaContext context,
  }) : super(
          key: 'invalid_type',
          name: context.name,
          schema: context.schema,
          value: context.value,
          message:
              'Invalid type of {{ valueType }}, expected {{ expectedType }}',
          variables: {
            'valueType': valueType.toString(),
            'expectedType': expectedType.toString(),
          },
        );
}

final class SchemaValidationError extends SchemaError {
  final List<ValidatorError> validations;
  SchemaValidationError({
    required this.validations,
    required SchemaContext context,
  }) : super(
          key: 'validation',
          name: context.name,
          schema: context.schema,
          value: context.value,
          message: '''
{{#each validations}}
{{message}}
{{/each}}
''',
          variables: {
            'validations': validations.map((e) => e.toMap()).toList(),
          },
        );

  ValidatorError? getConstraint(String key) {
    return validations.firstWhereOrNull((e) => e.key == key);
  }
}

final class NonNullableSchemaError extends SchemaError {
  NonNullableSchemaError({required SchemaContext context})
      : super(
          key: 'non_nullable',
          name: context.name,
          schema: context.schema,
          value: context.value,
          message: 'Non nullable value is null on {{schemaName}}',
          variables: {
            'schemaName': context.name,
            'value': context.value?.toString() ?? 'N/A',
          },
        );
}

final class NestedSchemaError extends SchemaError {
  final List<SchemaError> errors;

  NestedSchemaError({required this.errors, required SchemaContext context})
      : super(
          key: 'nested',
          name: context.name,
          schema: context.schema,
          value: context.value,
          message: '''
{{name}}
{{#each errors}}
{{name}}: {{message}}
{{/each}}
''',
          variables: {'errors': errors.map((e) => e.toMap()).toList()},
        ) {
    assert(schema is ObjectSchema || schema is ListSchema,
        'NestedSchemaError must be used with ObjectSchema or ListSchema');
  }
}

final class ValidatorError with ErrorBase {
  @override
  final Map<String, Object?>? variables;
  @override
  late final String template;
  @override
  final String key;

  ValidatorError({
    required this.key,
    required String message,
    this.variables,
  }) : template = message;
}

@visibleForTesting
class MockSchemaError extends SchemaError {
  MockSchemaError({
    SchemaContext context = const MockContext(),
    super.message = 'mock_message',
    super.variables,
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
