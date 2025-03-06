part of '../schema.dart';

final class DiscriminatedObjectSchema extends Schema<MapValue>
    with SchemaFluentMethods<DiscriminatedObjectSchema, MapValue> {
  final String _discriminatorKey;
  final Map<String, ObjectSchema> _schemas;

  const DiscriminatedObjectSchema({
    super.nullable,
    required String discriminatorKey,
    required Map<String, ObjectSchema> schemas,
    super.constraints,
    super.description,
    super.defaultValue,
  })  : _discriminatorKey = discriminatorKey,
        _schemas = schemas,
        super(type: SchemaType.discriminatedObject);

  @override
  SchemaError? _validateAsType(MapValue value) {
    final discriminatorValue = _getDiscriminatorValue(value);

    if (discriminatorValue == null) {
      return SchemaConstraintsError.single(
        _missingDiscriminatorKeyInValue(_discriminatorKey, value),
      );
    }
    final (errors, discriminatedSchema) = _validateDiscriminatedSchemas(
      schemas: _schemas,
      discriminatorKey: _discriminatorKey,
      discriminatorValue: discriminatorValue,
    );

    if (discriminatedSchema == null) {
      return SchemaConstraintsError.multiple(errors);
    }

    final result =
        discriminatedSchema.validate(value, debugName: discriminatorValue);

    return result.getErrorOrNull();
  }

  /// Returns the discriminator value for the discriminated object schema.
  String? _getDiscriminatorValue(MapValue value) {
    final discriminatorValue = value[_discriminatorKey];

    return discriminatorValue != null ? discriminatorValue as String : null;
  }

  /// Returns the discriminator key for the discriminated object schema.
  String getDiscriminatorKey() => _discriminatorKey;

  /// Returns the schemas for the discriminated object schema.
  List<ObjectSchema> getSchemas() => _schemas.values.toList();

  @override
  DiscriminatedObjectSchema call({
    bool? nullable,
    String? description,
    String? discriminatorKey,
    Map<String, ObjectSchema>? schemas,
    List<ConstraintValidator<MapValue>>? constraints,
    MapValue? defaultValue,
  }) {
    return copyWith(
      constraints: constraints,
      discriminatorKey: discriminatorKey,
      schemas: schemas,
      nullable: nullable,
      description: description,
      defaultValue: defaultValue,
    );
  }

  @override
  DiscriminatedObjectSchema copyWith({
    List<ConstraintValidator<MapValue>>? constraints,
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
      constraints: constraints ?? _constraints,
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

(List<ConstraintError>, ObjectSchema?) _validateDiscriminatedSchemas({
  required Map<String, ObjectSchema> schemas,
  required String discriminatorKey,
  required String discriminatorValue,
}) {
  // Check if schema exists for the discriminator value
  if (!schemas.containsKey(discriminatorValue)) {
    return (
      [_noSchemaForDiscriminatorValue(discriminatorKey, discriminatorValue)],
      null,
    );
  }
  final errors = <ConstraintError>[];
  // Validate the schema configuration
  for (final MapEntry(:key, value: schema) in schemas.entries) {
    final keyIsRequired = schema._required.contains(discriminatorKey);
    final propertyExists = schema._properties.containsKey(discriminatorKey);

    errors.addAll([
      if (!propertyExists)
        _missingDiscriminatorKeyInSchema(discriminatorKey, key),
      if (!keyIsRequired) _keyMustBeRequiredInSchema(discriminatorKey, schema),
    ]);
  }

  return errors.isEmpty
      ? (errors, schemas[discriminatorValue])
      : (errors, null);
}
