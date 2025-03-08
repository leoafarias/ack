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
    super.validators,
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
    // TODO: need to remove this
    if (_properties.containsKey('type')) {
      log('Warning: Property name "type" is reserved for OpenAPI schema');
    }

    if (_required.areNotUnique) {
      throw ArgumentError('Required properties must be unique');
    }
  }

  ObjectSchema extend(
    Map<String, Schema> properties, {
    bool? additionalProperties,
    List<String>? required,
    bool? nullable,
    String? description,
    List<ConstraintValidator<MapValue>>? validators,
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
          validators: prop._validators,
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
      validators: [..._validators, ...?validators],
      nullable: nullable,
      description: description,
      defaultValue: defaultValue,
    );
  }

  List<String> getRequiredProperties() => _required;

  Map<String, Schema> getProperties() => _properties;

  bool getAllowsAdditionalProperties() => _additionalProperties;

  @override
  List<ValidatorError> checkValidators(MapValue value) {
    final extraValidation = [
      UnallowedPropertiesConstraintViolation(this),
      PropertyRequiredConstraintViolation(this),
    ];

    return [
      ...super.checkValidators(value),
      ...extraValidation
          .map((v) => v.validate(value))
          .whereType<ValidatorError>(),
    ];
  }

  @override
  SchemaResult<MapValue> validateValue(Object? value) {
    final result = super.validateValue(value);

    if (result.isFail) return result;

    final resultValue = result.getOrNull();

    if (_nullable && resultValue == null) return SchemaResult.unit();

    final violations = <SchemaError>[];

    for (final entry in _properties.entries) {
      final propKey = entry.key;
      final propSchema = entry.value;

      final propValue = resultValue?[propKey];

      final propResult = propSchema.validate(propValue, debugName: propKey);

      if (propResult.isFail) {
        violations.add(propResult.getViolation());
      }
    }

    if (violations.isEmpty) return SchemaResult.ok(resultValue!);

    return SchemaResult.fail(
      NestedSchemaError(errors: violations, context: context),
    );
  }

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
    List<ConstraintValidator<MapValue>>? validators,
  }) {
    return extend(
      properties ?? _properties,
      additionalProperties: additionalProperties,
      required: required,
      nullable: nullable,
      description: description,
      validators: validators,
    );
  }

  @override
  ObjectSchema copyWith({
    bool? additionalProperties,
    List<String>? required,
    Map<String, Schema>? properties,
    List<ConstraintValidator<MapValue>>? validators,
    bool? nullable,
    String? description,
    MapValue? defaultValue,
  }) {
    return ObjectSchema(
      properties ?? _properties,
      additionalProperties: additionalProperties ?? _additionalProperties,
      validators: validators ?? _validators,
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
