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
    return buildError(
      template: 'Object must have at least $min properties',
      context: {'value': value, 'min': min},
    );
  }

  @override
  Map<String, Object?> toSchema() => {'minProperties': min};
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
      template: 'Object must have at most $max properties',
      context: {'value': value, 'max': max},
    );
  }

  @override
  Map<String, Object?> toSchema() => {'maxProperties': max};
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
      template:
          'Unallowed additional property: {{ key }} with value {{ value }}',
      context: {'key': key, 'value': propertyValue},
    );
  }
}

class PropertyRequiredConstraintError extends ConstraintValidator<MapValue> {
  final String key;
  final List<String> requiredKeys;

  PropertyRequiredConstraintError(this.key, this.requiredKeys)
      : super(
          name: 'property_is_required',
          description: 'Property is required in object',
        );

  @override
  bool isValid(MapValue value) => value.containsKey(key);

  @override
  ConstraintError onError(MapValue value) {
    return buildError(
      template: 'Property ({ key }) is required.',
      context: {'key': key, 'required_keys': requiredKeys},
    );
  }
}
