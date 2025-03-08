import 'package:ack/src/helpers.dart';
import 'package:ack/src/helpers/template.dart';
import 'package:meta/meta.dart';

import '../context.dart';
import '../schemas/schema.dart';

sealed class SchemaViolation extends SchemaContext {
  final Map<String, Object?> variables;
  late final Template template;
  late final render = template.render;
  final String name;

  SchemaViolation({
    required super.alias,
    required super.schema,
    required super.value,
    required String message,
    required this.name,
    this.variables = const {},
  }) {
    template = Template(message, data: variables);
  }

  String get message => template.render();

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'alias': alias,
      'schema': schema.toMap(),
      'value': value,
      'message': message,
      if (variables.isNotEmpty) 'variables': variables,
    };
  }

  @override
  String toString() =>
      '$runtimeType: name: $name, alias: $alias, schema: ${schema.runtimeType}, value: ${value ?? 'N/A'}, message: $message, variables: $variables';
}

final class UnknownSchemaViolation extends SchemaViolation {
  final Object error;
  final StackTrace stackTrace;
  UnknownSchemaViolation({
    required this.error,
    required this.stackTrace,
    required SchemaContext context,
  }) : super(
          name: 'unknown',
          alias: context.alias,
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
          name: 'invalid_type',
          alias: context.alias,
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
          name: 'constraints',
          alias: context.alias,
          schema: context.schema,
          value: context.value,
          message: 'Schema on {{schema_name}} violated: {{constraints}}',
          variables: {
            'schema_name': context.alias,
            'constraints': constraints.map((e) => e.toMap()).toList(),
          },
        );

  ConstraintViolation? getConstraint(String constraintName) {
    return constraints
        .firstWhereOrNull((e) => e.constraintName == constraintName);
  }
}

final class NonNullableSchemaViolation extends SchemaViolation {
  NonNullableSchemaViolation({required SchemaContext context})
      : super(
          name: 'non_nullable',
          alias: context.alias,
          schema: context.schema,
          value: context.value,
          message: 'Non nullable value is null on {{schema_name}}',
          variables: {
            'schema_name': context.alias,
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
          name: 'nested',
          alias: context.alias,
          schema: context.schema,
          value: context.value,
          message: '''
Schema violation of {{schema_name}}:

{{#each violations}}
  {{ name }}: {{ message }}
{{/each}}
''',
          variables: {
            'schema_name': context.alias,
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

final class ConstraintViolation {
  final Map<String, Object?>? variables;
  late final Template template;
  final String constraintName;

  late final render = template.render;

  ConstraintViolation({
    required this.constraintName,
    required String message,
    this.variables,
  }) {
    template = Template(message, data: variables);
  }

  String get message => template.render();

  Map<String, Object?> toMap() {
    return {
      'constraintName': constraintName,
      'message': message,
      if (variables != null && variables!.isNotEmpty) 'variables': variables,
    };
  }

  T getVariable<T>(String key) {
    final value = variables?[key];
    if (value == null) {
      throw ArgumentError('Variable $key not found');
    }

    return value as T;
  }

  @override
  String toString() => 'ConstraintViolation: $constraintName: $message';
}

@visibleForTesting
class MockSchemaViolation extends SchemaViolation {
  MockSchemaViolation({
    SchemaContext context = const MockContext(),
    super.message = 'mock_message',
    super.variables,
  }) : super(
          name: 'mock_schema',
          alias: context.alias,
          schema: context.schema,
          value: context.value,
        );
}

class MockContext extends SchemaContext {
  const MockContext()
      : super(
          alias: 'mock_context',
          schema: const StringSchema(),
          value: 'mock_value',
        );
}
