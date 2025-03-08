import 'package:ack/src/helpers.dart';
import 'package:ack/src/helpers/template.dart';
import 'package:meta/meta.dart';

import '../context.dart';
import '../schemas/schema.dart';

/// A mixin that provides common functionality for all types of violations.
mixin ViolationBase {
  /// The unique identifier for this violation type.
  String get key;

  /// Variables used to render the message template.
  Map<String, Object?>? get variables;

  /// The message template.
  Template get template;

  /// Renders the message with all variables.
  String get message => template.render();

  /// Returns a function that renders the template.
  late final render = template.render;

  /// Converts the violation to a map representation.
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

sealed class SchemaViolation extends SchemaContext with ViolationBase {
  @override
  final String key;

  @override
  final Map<String, Object?> variables;

  @override
  late final Template template;

  SchemaViolation({
    required super.name,
    required super.schema,
    required super.value,
    required String message,
    required this.key,
    this.variables = const {},
  }) {
    template = Template(message, data: variables);
  }

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

final class UnknownSchemaViolation extends SchemaViolation {
  final Object error;
  final StackTrace stackTrace;
  UnknownSchemaViolation({
    required this.error,
    required this.stackTrace,
    required SchemaContext context,
  }) : super(
          key: 'unknown',
          name: context.name,
          schema: context.schema,
          value: context.value,
          message: 'Unknown schema violation: {{error}} \n{{stackTrace}}',
          variables: {
            'error': error.toString(),
            'stackTrace': stackTrace.toString(),
          },
        );
}

final class InvalidTypeSchemaViolation extends SchemaViolation {
  final Type valueType;
  final Type expectedType;
  InvalidTypeSchemaViolation({
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

final class SchemaConstraintViolation extends SchemaViolation {
  final List<ConstraintViolation> constraints;
  SchemaConstraintViolation({
    required this.constraints,
    required SchemaContext context,
  }) : super(
          key: 'constraints',
          name: context.name,
          schema: context.schema,
          value: context.value,
          message: 'Schema on {{schema_name}} violated: {{constraints}}',
          variables: {
            'schema_name': context.name,
            'constraints': constraints.map((e) => e.toMap()).toList(),
          },
        );

  ConstraintViolation? getConstraint(String key) {
    return constraints.firstWhereOrNull((e) => e.key == key);
  }
}

final class NonNullableSchemaViolation extends SchemaViolation {
  NonNullableSchemaViolation({required SchemaContext context})
      : super(
          key: 'non_nullable',
          name: context.name,
          schema: context.schema,
          value: context.value,
          message: 'Non nullable value is null on {{schema_name}}',
          variables: {
            'schema_name': context.name,
            'value': context.value?.toString() ?? 'N/A',
          },
        );
}

final class NestedSchemaViolation extends SchemaViolation {
  final Map<String, SchemaViolation> violations;

  NestedSchemaViolation({
    required this.violations,
    required SchemaContext context,
  }) : super(
          key: 'nested',
          name: context.name,
          schema: context.schema,
          value: context.value,
          message: '''
Schema violation of {{schema_name}}:

{{#each violations}}
  {{ name }}: {{ message }}
{{/each}}
''',
          variables: {
            'schema_name': context.name,
            'violations': {
              for (final entry in violations.entries)
                entry.key: entry.value.toMap(),
            },
          },
        ) {
    assert(schema is ObjectSchema || schema is ListSchema,
        'NestedSchemaViolation must be used with ObjectSchema or ListSchema');
  }
}

final class ConstraintViolation with ViolationBase {
  @override
  final Map<String, Object?>? variables;
  @override
  late final Template template;
  @override
  final String key;

  ConstraintViolation({
    required this.key,
    required String message,
    this.variables,
  }) {
    template = Template(message, data: variables);
  }
}

@visibleForTesting
class MockSchemaViolation extends SchemaViolation {
  MockSchemaViolation({
    SchemaContext context = const MockContext(),
    super.message = 'mock_message',
    super.variables,
  }) : super(
          key: 'mock_schema',
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
