part of '../schema.dart';

/// Provides validation methods for [ObjectSchema].
extension ObjectSchemaValidatorsExt on ObjectSchema {
  /// {@macro object_min_properties_validator}
  /// Example:
  /// ```dart
  /// final schema = Ack.object({
  ///   'id': Ack.string(),
  ///   'name': Ack.string(),
  /// }).minProperties(1);
  /// ```
  ObjectSchema minProperties(int min) {
    return withConstraints([MinPropertiesObjectValidator(min: min)]);
  }

  /// {@macro object_max_properties_validator}
  /// Example:
  /// ```dart
  /// final schema = Ack.object({
  ///   'id': Ack.string(),
  ///   'name': Ack.string(),
  /// }).maxProperties(3);
  /// ```
  ObjectSchema maxProperties(int max) {
    return withConstraints([MaxPropertiesObjectValidator(max: max)]);
  }
}

/// {@template object_min_properties_validator}
/// Validator that checks if a [Map] has at least a minimum number of properties
///
/// Equivalent of calling `map.length >= min`
/// {@endtemplate}
class MinPropertiesObjectValidator extends ConstraintValidator<MapValue>
    with OpenAPiSpecOutput<MapValue> {
  /// The minimum number of properties required
  final int min;

  const MinPropertiesObjectValidator({required this.min})
      : super(
          name: 'object_min_properties',
          description: 'Object must have at least $min properties',
        );

  @override
  bool isValid(MapValue value) => value.length >= min;

  @override
  ConstraintError onError(MapValue value) {
    return buildError(extra: {'value': value, 'min': min});
  }

  @override
  Map<String, Object?> toSchema() => {'minProperties': min};

  @override
  String get errorTemplate => 'Object must have at least $min properties';
}

/// {@template object_max_properties_validator}
/// Validator that checks if a [Map] has at most a maximum number of properties
///
/// Equivalent of calling `map.length <= max`
/// {@endtemplate}
class MaxPropertiesObjectValidator extends ConstraintValidator<MapValue>
    with OpenAPiSpecOutput<MapValue> {
  /// The maximum number of properties allowed
  final int max;

  const MaxPropertiesObjectValidator({required this.max})
      : super(
          name: 'object_max_properties',
          description: 'Object must have at most $max properties',
        );

  @override
  bool isValid(MapValue value) => value.length <= max;

  @override
  ConstraintError onError(MapValue value) {
    return buildError(
      extra: {'value': value, 'max': max, 'value_length': value.length},
    );
  }

  @override
  Map<String, Object?> toSchema() => {'maxProperties': max};

  @override
  String get errorTemplate => '''
Object must have at most {{ extra.max }} properties, but has {{ extra.value_length }}
''';
}

class UnallowedPropertyConstraintError extends ConstraintValidator<MapValue> {
  final String key;

  UnallowedPropertyConstraintError(this.key)
      : super(
          name: 'unallowed_property',
          description: 'Unallowed additional property: $key',
        );

  @override
  bool isValid(MapValue value) => !value.containsKey(key);

  @override
  ConstraintError onError(MapValue value) {
    final propertyValue = value[key];

    return buildError(
      extra: {'property_key': key, 'property_value': propertyValue},
    );
  }

  @override
  String get errorTemplate => '''
Unallowed additional property: {{ extra.property_key }} with value {{ extra.property_value }}
''';
}

class PropertyRequiredConstraintError extends ConstraintValidator<MapValue> {
  final String key;
  final List<String> requiredKeys;

  PropertyRequiredConstraintError(this.key, this.requiredKeys)
      : super(
          name: 'property_is_required',
          description: 'Property ($key) is required',
        );

  @override
  bool isValid(MapValue value) {
    // Valid if the key is not required OR if it is present in the value.
    return !requiredKeys.contains(key) || value.containsKey(key);
  }

  @override
  ConstraintError onError(MapValue value) {
    return buildError(
      extra: {'key': key, 'required_keys': requiredKeys, 'value': value},
    );
  }

  @override
  String get errorTemplate => '''
Property "$key" is required but was not provided.

Required properties:
{{ extra.required_keys }}
''';
}
