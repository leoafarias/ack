part of '../schema.dart';

typedef MapValue = Map<String, Object?>;

final class ObjectSchema extends Schema<MapValue>
    with SchemaFluentMethods<ObjectSchema, MapValue> {
  final bool _additionalProperties;
  final List<String> _required;
  final Map<String, Schema> _properties;

  ObjectSchema(
    this._properties, {
    bool additionalProperties = false,
    super.constraints,
    super.description,
    List<String> required = const [],
    super.nullable,
    super.defaultValue,
  })  : _additionalProperties = additionalProperties,
        _required = required,
        super(type: SchemaType.object) {
    if (!_properties.keys.containsAll(required)) {
      throw ArgumentError(
        'Required properties must be present in the properties map [${_properties.keys.getNonContainedValues(required).join(', ')}]',
      );
    }

    // Check if properties has a key called 'type'
    if (_properties.containsKey('type')) {
      log('Warning: Property name "type" is reserved for OpenAPI schema');
    }

    if (_required.areNotUnique) {
      throw ArgumentError('Required properties must be unique');
    }
  }

  @override
  SchemaError? _validateAsType(MapValue value) {
    final error = super._validateAsType(value);

    if (error != null) return error;

    final constraintErrors = <String, SchemaError>{};

    // Validate properties
    for (final key in _properties.keys) {
      final requiredError =
          PropertyRequiredConstraintError(key, _required).validate(value);
      if (requiredError != null) {
        constraintErrors[key] = SchemaConstraintsError.single(requiredError);
        continue;
      }

      final schemaProp = _properties[key]!;

      final propError = schemaProp.validateSchema(value[key]);

      if (propError == null) continue;

      constraintErrors[key] = propError;
    }

    if (!_additionalProperties) {
      final differentKeys =
          value.keys.toSet().difference(_properties.keys.toSet());
      for (final key in differentKeys) {
        final unallowedError =
            UnallowedPropertyConstraintError(key).validate(value);
        if (unallowedError != null) {
          constraintErrors[key] = SchemaConstraintsError.single(unallowedError);
        }
      }
    }

    if (constraintErrors.isEmpty) return null;

    return ObjectSchemaError(errors: constraintErrors);
  }

  /// Validate the [value] as a JSON string
  ///
  /// This method is useful for validating JSON strings against the schema.
  ///
  /// If the value is not a JSON string, it will be converted to a JSON string
  /// using [jsonEncode].
  SchemaResult<MapValue> validateJson(String value, {String? debugName}) {
    try {
      return validate(
        jsonDecode(value) as Map<String, Object?>,
        debugName: debugName,
      );
    } catch (e) {
      return SchemaResult.fail(InvalidJsonFormatContraintError(json: value));
    }
  }

  ObjectSchema extend(
    Map<String, Schema> properties, {
    bool? additionalProperties,
    List<String>? required,
    bool? nullable,
    String? description,
    List<ConstraintValidator<MapValue>>? constraints,
    MapValue? defaultValue,
  }) {
    // if property SchemaValue is of SchemaMap, we need to merge them
    final mergedProperties = {..._properties};

    for (final entry in properties.entries) {
      final key = entry.key;
      final prop = entry.value;

      final existingProp = mergedProperties[key];

      if (existingProp is ObjectSchema && prop is ObjectSchema) {
        mergedProperties[key] = existingProp.extend(
          prop._properties,
          additionalProperties: prop._additionalProperties,
          required: prop._required,
          constraints: prop._constraints,
        );
      } else {
        mergedProperties[key] = prop;
      }
    }

    final requiredProperties = <String>{..._required, ...?required}.toList();

    return copyWith(
      additionalProperties: additionalProperties,
      required: requiredProperties,
      properties: mergedProperties,
      constraints: [..._constraints, ...?constraints],
      nullable: nullable,
      description: description,
      defaultValue: defaultValue,
    );
  }

  List<String> getRequiredProperties() => _required;

  Map<String, Schema> getProperties() => _properties;

  bool getAllowsAdditionalProperties() => _additionalProperties;

  /// Will extend the ObjectSchema with the values passed into call method
  ///
  /// This method is intended to be used to extend the schema with additional
  /// properties, required properties, nullable, strict, description, and constraints.
  ///
  /// Example:
  /// ```dart
  /// final schema = Ack.object({
  ///   'name': Ack.string,
  /// })(additionalProperties: true);
  /// ```
  @override
  ObjectSchema call({
    bool? nullable,
    String? description,
    bool? additionalProperties,
    List<String>? required,
    Map<String, Schema>? properties,
    List<ConstraintValidator<MapValue>>? constraints,
  }) {
    return extend(
      properties ?? _properties,
      additionalProperties: additionalProperties,
      required: required,
      nullable: nullable,
      description: description,
      constraints: constraints,
    );
  }

  @override
  ObjectSchema copyWith({
    bool? additionalProperties,
    List<String>? required,
    Map<String, Schema>? properties,
    List<ConstraintValidator<MapValue>>? constraints,
    bool? nullable,
    String? description,
    MapValue? defaultValue,
  }) {
    return ObjectSchema(
      properties ?? _properties,
      additionalProperties: additionalProperties ?? _additionalProperties,
      constraints: constraints ?? _constraints,
      description: description ?? _description,
      required: required ?? _required,
      nullable: nullable ?? _nullable,
      defaultValue: defaultValue ?? _defaultValue,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      ...super.toMap(),
      'properties':
          _properties.map((key, value) => MapEntry(key, value.toMap())),
      'additionalProperties': _additionalProperties,
      'required': _required,
    };
  }
}
