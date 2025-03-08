import 'package:ack/src/helpers.dart';
import 'package:ack/src/helpers/template.dart';

import '../context.dart';
import '../schemas/schema.dart';

abstract class AckViolation {
  final String key;
  final Map<String, Object?>? extra;

  late final ViolationTemplate template;

  late final render = template.render;

  AckViolation({required this.key, required String message, this.extra}) {
    template = ViolationTemplate(message, data: extra);
  }

  String get message => template.render();

  Map<String, Object?> toMap() {
    return {
      'key': key,
      'message': message,
      if (extra != null) 'extra': extra,
    };
  }

  String toJson() => prettyJson(toMap());

  @override
  String toString() => '$runtimeType: ${toJson()}';
}

sealed class SchemaViolation extends AckViolation {
  final SchemaContext context;
  SchemaViolation({
    required super.key,
    required super.message,
    Map<String, Object?>? extra,
    required this.context,
  }) : super(extra: {...context.extra, ...?extra});

  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'context': context.toMap()};
  }
}

final class ExceptionViolation extends SchemaViolation {
  final Object error;
  final StackTrace stackTrace;
  ExceptionViolation({
    required this.error,
    required this.stackTrace,
    required Schema schema,
  }) : super(
          key: 'out_of_context',
          message: 'Out of context',
          extra: {
            'error': error.toString(),
            'stackTrace': stackTrace.toString(),
          },
          context: SchemaContext(
            name: schema.type.name,
            schema: schema,
            value: null,
          ),
        );
}

final class UnknownSchemaViolation extends SchemaViolation {
  final Object error;
  final StackTrace stackTrace;
  UnknownSchemaViolation({
    required this.error,
    required this.stackTrace,
    required super.context,
  }) : super(
          key: 'unknown_exception',
          message: 'Unknown Exception when validating schema {{ error }}',
          extra: {
            'error': error.toString(),
            'stackTrace': stackTrace.toString(),
          },
        );
}

final class InvalidTypeViolation extends ConstraintViolation {
  final Type valueType;
  final Type expectedType;
  InvalidTypeViolation({
    required this.valueType,
    required this.expectedType,
  }) : super(
          key: 'invalid_type',
          message:
              'Invalid type of {{ value_type }}, expected {{ expected_type }}',
          extra: {
            'value_type': valueType.toString(),
            'expected_type': expectedType.toString(),
          },
        );
}

final class SchemaConstraintViolation extends SchemaViolation {
  final List<ConstraintViolation> constraints;
  SchemaConstraintViolation({
    required this.constraints,
    required super.context,
  }) : super(
          key: 'constraints',
          message: 'Total of {{ constraints.length }} constraint violations',
          extra: {'constraints': constraints.map((e) => e.toMap()).toList()},
        );
}

final class NonNullableViolation extends ConstraintViolation {
  NonNullableViolation()
      : super(
          key: 'non_nullable_value',
          message: 'Non nullable value is null',
        );
}

final class ObjectSchemaViolation extends SchemaViolation {
  final Map<String, SchemaViolation> violations;

  ObjectSchemaViolation({required this.violations, required super.context})
      : super(
          key: 'object',
          message:
              'Object schema total of {{ violations.length }} validation failed',
          extra: {
            'violations': {
              for (final entry in violations.entries)
                entry.key: entry.value.toMap(),
            },
          },
        );
}

final class ListSchemaViolation extends SchemaViolation {
  final Map<int, SchemaViolation> violations;

  ListSchemaViolation({required this.violations, required super.context})
      : super(
          key: 'list',
          message: 'List schema items validation failed',
          extra: {
            'violations': {
              for (final entry in violations.entries)
                entry.key: entry.value.toMap(),
            },
          },
        );
}

final class ConstraintViolation extends AckViolation {
  ConstraintViolation({
    required super.key,
    required super.message,
    super.extra,
  });
}
