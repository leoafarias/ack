part of '../schema.dart';

List<ConstraintError> _validateRequiredProperties(
  MapValue value,
  Iterable<String> requiredKeys,
) {
  return requiredKeys
      .toSet()
      .difference(value.keys.toSet())
      .map(_requiredPropertyError)
      .toList();
}

List<ConstraintError> _validateUnallowedProperties(
  MapValue value,
  Iterable<String> allowedKeys,
) {
  return value.keys
      .toSet()
      .difference(allowedKeys.toSet())
      .map(_unallowedPropertyError)
      .toList();
}

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

ConstraintError _unallowedPropertyError(String property) {
  return ConstraintError(
    name: 'property_unallowed',
    message: 'Unallowed additional property: $property',
    context: {'property': property},
  );
}

ConstraintError _requiredPropertyError(String property) {
  return ConstraintError(
    name: 'property_required',
    message: 'Required property: $property',
    context: {'property': property},
  );
}
