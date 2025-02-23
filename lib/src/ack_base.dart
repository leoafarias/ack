import 'package:ack/src/helpers.dart';
import 'package:meta/meta.dart';

part 'schemas/boolean/boolean_schema.dart';
part 'schemas/boolean/boolean_validators.dart';
part 'schemas/discriminated/discriminated_schema.dart';
part 'schemas/discriminated/discriminated_validators.dart';
part 'schemas/list/list_schema.dart';
part 'schemas/list/list_validators.dart';
part 'schemas/num/num_schema.dart';
part 'schemas/num/num_validators.dart';
part 'schemas/object/object_schema.dart';
part 'schemas/object/object_validators.dart';
part 'schemas/schema.dart';
part 'schemas/string/string_schema.dart';
part 'schemas/string/string_validators.dart';
part 'validation/ack_exception.dart';
part 'validation/constraint_error.dart';
part 'validation/constraint_validator.dart';
part 'validation/schema_error.dart';
part 'validation/schema_result.dart';

typedef IntType = int;
typedef DoubleType = double;

final class Ack<S extends Schema<T>, T extends Object> extends Schema<T> {
  final S _schema;

  const Ack._(this._schema);

  S nullable() => _schema.copyWith(nullable: true) as S;

  Ack<S, T> strict() => copyWith(strict: true);

  @override
  bool get isStrict => _schema.isStrict;

  @override
  T? _tryParse(Object value) => _schema._tryParse(value);

  @override
  Ack<S, T> copyWith({
    bool? nullable,
    List<ConstraintValidator<T>>? constraints,
    bool? strict,
  }) =>
      Ack._(_schema.copyWith(
        nullable: nullable,
        constraints: constraints,
        strict: strict,
      ) as S);

  S withConstraints(List<ConstraintValidator<T>> constraints) {
    return _schema.copyWith(constraints: constraints) as S;
  }

  S call() => _schema;

  void validateOrThrow(Object value) {
    final result = validate(value);

    result.onFail((errors) {
      throw AckException(errors);
    });
  }

  T transformOrThrow(T Function(Object value) mapper, Object value) {
    final result = validate(value);

    return result.match(
      onOk: mapper,
      onFail: (errors) => throw AckException(errors),
    );
  }

  T? transform(T Function(Object value) mapper, Object value) {
    final result = validate(value);

    return result.match(
      onOk: mapper,
      onFail: (_) => null,
    );
  }

  @override
  SchemaResult validate(Object? value) {
    try {
      return _schema.validate(value);
    } catch (e, stackTrace) {
      return Fail(
        [
          SchemaError.unknownException(
            error: e,
            stackTrace: stackTrace,
          ),
        ],
      );
    }
  }

  Ack<ListSchema<T>, List<T>> get list => Ack._(ListSchema(_schema));

  static Ack<DiscriminatedObjectSchema, MapValue> discriminated({
    required String discriminatorKey,
    required Map<String, ObjectSchema> schemas,
  }) {
    return Ack._(
      DiscriminatedObjectSchema(
        discriminatorKey: discriminatorKey,
        schemas: schemas,
      ),
    );
  }

  static Ack<ObjectSchema, MapValue> object(
    Map<String, Schema> properties, {
    bool additionalProperties = false,
    List<String> required = const [],
  }) {
    return Ack._(
      ObjectSchema(
        properties,
        additionalProperties: additionalProperties,
        required: required,
      ),
    );
  }

  static Ack<StringSchema, String> enumString(List<String> values) {
    return Ack._(Ack.string.withConstraints([EnumValidator(values)]));
  }

  static Ack<StringSchema, String> enumValues(List<Enum> values) {
    return enumString(values.map((e) => e.name).toList());
  }

  static const string = Ack<StringSchema, String>._(StringSchema());

  static const boolean = Ack<BooleanSchema, bool>._(BooleanSchema());

  static const int = Ack<IntSchema, IntType>._(IntSchema());
  static const double = Ack<DoubleSchema, DoubleType>._(DoubleSchema());
}

extension OkMapExt on Ack<ObjectSchema, MapValue> {
  Ack<ObjectSchema, MapValue> extend(
    Map<String, Schema> properties, {
    bool? additionalProperties,
    List<String>? required,
    List<ConstraintValidator<MapValue>>? constraints,
  }) {
    return Ack._(
      _schema.extend(
        properties,
        additionalProperties: additionalProperties,
        required: required,
        constraints: constraints,
      ),
    );
  }
}
