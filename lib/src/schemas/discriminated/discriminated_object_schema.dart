part of '../schema.dart';

final class DiscriminatedObjectSchema extends Schema<MapValue>
    with SchemaFluentMethods<DiscriminatedObjectSchema, MapValue> {
  final String _discriminatorKey;
  final Map<String, ObjectSchema> _schemas;

  DiscriminatedObjectSchema({
    super.nullable,
    required String discriminatorKey,
    required Map<String, ObjectSchema> schemas,
    super.validators,
    super.description,
    super.defaultValue,
  })  : _discriminatorKey = discriminatorKey,
        _schemas = schemas,
        super(type: SchemaType.discriminatedObject);

  /// Returns the discriminator value for the discriminated object schema.
  String? _getDiscriminator(MapValue value) {
    final discriminatorValue = value[_discriminatorKey];

    return discriminatorValue != null ? discriminatorValue as String : null;
  }

  /// Returns the discriminator key for the discriminated object schema.
  String getDiscriminatorKey() => _discriminatorKey;

  /// Returns the schemas for the discriminated object schema.
  List<ObjectSchema> getSchemas() => _schemas.values.toList();

  @override
  SchemaResult<MapValue> validateValue(Object? value) {
    final result = super.validateValue(value);

    if (result.isFail) return result;

    final mapValue = result.getOrNull();

    if (_nullable && mapValue == null) return SchemaResult.unit();

    final violations = [
      DiscriminatorSchemaStructureViolation(_discriminatorKey)
          .validate(_schemas),
      DiscriminatorValueViolation(_discriminatorKey, _schemas)
          .validate(mapValue!),
    ].whereType<ValidatorError>();

    if (violations.isNotEmpty) {
      return SchemaResult.fail(
        SchemaValidationError(
          validations: violations.toList(),
          context: context,
        ),
      );
    }

    final discrimnatorValue = _getDiscriminator(mapValue);

    final discriminatedSchema = _schemas[discrimnatorValue]!;

    return discriminatedSchema.validate(mapValue, debugName: discrimnatorValue);
  }

  @override
  DiscriminatedObjectSchema call({
    bool? nullable,
    String? description,
    String? discriminatorKey,
    Map<String, ObjectSchema>? schemas,
    List<ConstraintValidator<MapValue>>? validators,
    MapValue? defaultValue,
  }) {
    return copyWith(
      validators: validators,
      discriminatorKey: discriminatorKey,
      schemas: schemas,
      nullable: nullable,
      description: description,
      defaultValue: defaultValue,
    );
  }

  @override
  DiscriminatedObjectSchema copyWith({
    List<ConstraintValidator<MapValue>>? validators,
    String? discriminatorKey,
    Map<String, ObjectSchema>? schemas,
    bool? nullable,
    String? description,
    MapValue? defaultValue,
  }) {
    return DiscriminatedObjectSchema(
      nullable: nullable ?? _nullable,
      discriminatorKey: discriminatorKey ?? _discriminatorKey,
      schemas: schemas ?? _schemas,
      validators: validators ?? _validators,
      description: description ?? _description,
      defaultValue: defaultValue ?? _defaultValue,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      'discriminatorKey': _discriminatorKey,
      'schemas': _schemas.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}
