import 'dart:convert';

import 'package:ack/src/constraints/constraint.dart';
import 'package:ack/src/helpers.dart';
import 'package:meta/meta.dart';

import '../schemas/schema.dart';

final class InvalidTypeConstraint<T extends Object> extends Constraint<Object>
    with Validator<Object> {
  InvalidTypeConstraint()
      : super(key: 'invalid_type', description: 'Type should be $T');

  @override
  bool isValid(Object? value) => value is T;

  @override
  ConstraintError<InvalidTypeConstraint<T>>? validate(Object? value) =>
      isValid(value)
          ? null
          : ConstraintError(
              key: key,
              message: 'Invalid type: ${value.runtimeType}. Expected type: $T',
              constraint: this,
            );
  @override
  String buildMessage(Object? value) =>
      'Invalid type: ${value.runtimeType}. Expected type: $T';
}

final class NonNullableConstraint extends Constraint<Object> {
  NonNullableConstraint()
      : super(key: 'non_nullable', description: 'Value cannot be null');
}

/// {@template date_time_validator}
/// Validates that the input string can be parsed into a [DateTime] object.
///
/// Equivalent of calling `DateTime.tryParse(value) != null`
/// {@endtemplate}
class StringDateTimeConstraint extends Constraint<String>
    with Validator<String>, OpenApiSpec<String> {
  /// {@macro date_time_validator}
  const StringDateTimeConstraint()
      : super(
          key: 'string_date_time',
          description: 'Must be a valid date time string',
        );

  @override
  bool isValid(String value) => DateTime.tryParse(value) != null;

  @override
  String buildMessage(String value) =>
      'The value "$value" is not a valid date time. Expected format: ISO 8601 (e.g., {{ example }}).';

  @override
  Map<String, Object?> toOpenApiSpec() => {'format': 'date-time'};
}

/// {@template date_validator}
/// Validates that the input string can be parsed into a date in YYYY-MM-DD format.
///
/// For example: `2017-07-21`
/// {@endtemplate}
class StringDateConstraint extends Constraint<String>
    with Validator<String>, OpenApiSpec<String> {
  /// {@macro date_validator}
  const StringDateConstraint()
      : super(
          key: 'string_date',
          description: 'Must be a valid date string in YYYY-MM-DD format',
        );

  @override
  bool isValid(String value) {
    // Attempt to parse the input string using DateTime.tryParse
    final date = DateTime.tryParse(value);
    if (date == null) {
      // Parsing failed (invalid date or format)
      return false;
    }
    // Reconstruct the date in 'yyyy-MM-dd' format
    final formatted = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    // Check if the reconstructed string matches the input
    return formatted == value;
  }

  @override
  String buildMessage(String value) =>
      'The value "$value" is not a valid date. Expected format: YYYY-MM-DD (e.g., 2017-07-21).';

  @override
  Map<String, Object?> toOpenApiSpec() => {'format': 'date'};
}

/// {@template enum_validator}
/// Validates that the input string is one of the allowed enum values
///
/// Equivalent of calling `enumValues.contains(value)`
/// {@endtemplate}
class StringEnumConstraint extends Constraint<String>
    with Validator<String>, OpenApiSpec<String> {
  /// The allowed enum values
  final List<String> enumValues;

  /// {@macro enum_validator}
  const StringEnumConstraint(this.enumValues)
      : super(key: 'string_enum', description: 'Must be one of: $enumValues}');

  @override
  bool isValid(String value) => enumValues.contains(value);

  @override
  String buildMessage(String value) {
    final closestMatch = findClosestStringMatch(value, enumValues);
    final closestMatchMessage =
        closestMatch.isTruthy ? '(Closest match: "${closestMatch!}")' : '';

    return 'Invalid value "$value". Allowed values are: $enumValues. $closestMatchMessage';
  }

  @override
  Map<String, Object?> toOpenApiSpec() => {'enum': enumValues};
}

/// {@template email_validator}
/// Validates that the input string matches an email pattern
///
/// Uses regex pattern: `^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$`
/// {@endtemplate}
class StringEmailConstraint extends StringRegexConstraint {
  /// {@macro email_validator}
  StringEmailConstraint()
      : super(
          key: 'string_email',
          pattern: r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
          example: 'example@domain.com',
        );
}

/// {@template hex_color_validator}
/// Validates that the input string matches a hex color pattern
///
/// Uses regex pattern: `^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$`
/// {@endtemplate}
class StringHexColorValidator extends StringRegexConstraint {
  /// {@macro hex_color_validator}
  StringHexColorValidator()
      : super(
          key: 'string_hex_color',
          example: '#f0f0f0',
          pattern: r'^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$',
        );
}

/// {@template not_one_of_validator}
/// Validates that the input string is not one of the disallowed values
///
/// Uses a regex pattern to match the exact string against the disallowed values
/// Example: For values ['a', 'b', 'c'], pattern will be '^(?!a|b|c).*$'
/// {@endtemplate}
class StringNotOneOfValidator extends StringRegexConstraint {
  /// The disallowed values
  final List<String> disallowedValues;

  /// {@macro not_one_of_validator}
  StringNotOneOfValidator(this.disallowedValues)
      : super(
          key: 'string_not_one_of',
          pattern:
              '^(?!${disallowedValues.map((e) => RegExp.escape(e)).join('|')}).*\$',
          example: 'Any value except: $disallowedValues',
        );

  @override
  bool isValid(String value) => !disallowedValues.contains(value);

  @override
  String buildMessage(String value) {
    return 'The value "$value" is not allowed. Disallowed values: $disallowedValues.';
  }
}

/// {@template not_empty_validator}
/// Validates that the input string is not empty
///
/// Equivalent of calling `value.isNotEmpty`
/// {@endtemplate}
class StringNotEmptyValidator extends Constraint<String>
    with Validator<String> {
  /// {@macro not_empty_validator}
  const StringNotEmptyValidator()
      : super(key: 'string_not_empty', description: 'String cannot be empty');

  @override
  bool isValid(String value) => value.isNotEmpty;

  @override
  String buildMessage(String value) {
    return 'The string must not be empty.';
  }
}

/// {@template is_json_validator}
/// Validates that the input string is a valid JSON string
///
/// Equivalent of calling `isJsonValue(value)`
/// {@endtemplate}
class StringJsonValidator extends Constraint<String> with Validator<String> {
  /// {@macro is_json_string_validator}
  const StringJsonValidator()
      : super(key: 'string_json', description: 'Must be a valid JSON string');

  @override
  bool isValid(String value) {
    try {
      if (looksLikeJson(value)) {
        jsonDecode(value);

        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  String buildMessage(String value) {
    return 'The value "$value" is not valid JSON.';
  }
}

/// Base class for regex-based string validators
class StringRegexConstraint extends Constraint<String>
    with Validator<String>, OpenApiSpec<String> {
  /// The regex pattern to match
  final String pattern;

  /// An example value that matches the pattern
  final String example;

  /// {@macro regex_pattern_string_validator}
  StringRegexConstraint({
    required super.key,
    required this.pattern,
    required this.example,
  }) : super(description: 'Must match the pattern: $key  . Example $example') {
    // Assert that string is not empty
    // and taht it starts with ^ and ends with $ for a complete match
    if (pattern.isEmpty) {
      throw ArgumentError('Pattern cannot be empty');
    }
    if (!pattern.startsWith('^') || !pattern.endsWith(r'$')) {
      throw ArgumentError(r'Pattern must start with ^ and end with \$');
    }
  }

  @override
  bool isValid(String value) {
    try {
      final regex = RegExp(pattern);

      return regex.hasMatch(value);
    } catch (e) {
      return false;
    }
  }

  @override
  String buildMessage(String value) {
    return 'The value "$value" does not match the required pattern for $key. Expected format: "$example".';
  }

  @override
  Map<String, Object?> toMap() => {'pattern': pattern, 'name': key};

  @override
  Map<String, Object?> toOpenApiSpec() => {'pattern': pattern, 'name': key};
}

/// {@template is_empty_validator}
/// Validates that the input string is empty
///
/// Equivalent of calling `value.isEmpty`
/// {@endtemplate}
class StringEmptyConstraint extends Constraint<String> with Validator<String> {
  /// {@macro is_empty_validator}
  const StringEmptyConstraint()
      : super(key: 'string_empty', description: 'String must be empty');

  @override
  bool isValid(String value) => value.isEmpty;

  @override
  String buildMessage(String value) {
    return 'The string must be empty. Got: "$value"';
  }
}

/// {@template min_length_validator}
/// Validates that the input string length is at least a certain value
///
/// Equivalent of calling `value.length >= min`
/// {@endtemplate}
class StringMinLengthConstraint extends Constraint<String>
    with Validator<String>, OpenApiSpec<String> {
  /// The minimum length
  final int min;

  /// {@macro min_length_validator}
  const StringMinLengthConstraint(this.min)
      : super(
          key: 'string_min_length',
          description: 'String must be at least $min characters long',
        );

  @override
  bool isValid(String value) => value.length >= min;

  @override
  String buildMessage(String value) {
    return 'The string length (${value.length}) is too short; it must be at least ($min) characters.';
  }

  @override
  Map<String, Object?> toOpenApiSpec() => {'minLength': min};
}

/// {@template max_length_validator}
/// Validates that the input string length is at most a certain value
///
/// Equivalent of calling `value.length <= max`
/// {@endtemplate}
class StringMaxLengthConstraint extends Constraint<String>
    with Validator<String>, OpenApiSpec<String> {
  /// The maximum length
  final int max;

  /// {@macro max_length_validator}
  const StringMaxLengthConstraint(this.max)
      : super(
          key: 'string_max_length',
          description: 'String must be at most $max characters long',
        );

  @override
  bool isValid(String value) => value.length <= max;

  @override
  @visibleForTesting
  String buildMessage(String value) {
    return 'The string length (${value.length}) exceeds the maximum allowed of ($max) characters.';
  }

  @override
  Map<String, Object?> toOpenApiSpec() => {'maxLength': max};
}

/// {@template unique_items_list_validator}
/// Validator that checks if a [List] has unique items
///
/// Equivalent of calling `list.toSet().length == list.length`
/// {@endtemplate}
class ListUniqueItemsConstraint<T extends Object> extends Constraint<List<T>>
    with Validator<List<T>>, OpenApiSpec<List<T>> {
  /// {@macro unique_items_list_validator}
  const ListUniqueItemsConstraint()
      : super(
          key: 'list_unique_items',
          description: 'List items must be unique',
        );

  @override
  bool isValid(List<T> value) => value.duplicates.isEmpty;

  @override
  String buildMessage(List<T> value) {
    final nonUniqueValues = value.duplicates;

    return 'The list contains duplicate items: $nonUniqueValues. All items must be unique.';
  }

  @override
  Map<String, Object?> toOpenApiSpec() => {'uniqueItems': true};
}

/// {@template min_items_list_validator}
/// Validator that checks if a [List] has at least a certain number of items
///
/// Equivalent of calling `list.length >= min`
/// {@endtemplate}
class ListMinItemsConstraint<T extends Object> extends Constraint<List<T>>
    with Validator<List<T>>, OpenApiSpec<List<T>> {
  /// The minimum number of items
  final int min;

  /// {@macro min_items_list_validator}
  const ListMinItemsConstraint(this.min)
      : super(
          key: 'list_min_items',
          description: 'List must have at least $min items',
        );

  @override
  bool isValid(List<T> value) => value.length >= min;

  @override
  String buildMessage(List<T> value) {
    return 'The list has only ${value.length} items; at least $min items are required.';
  }

  @override
  Map<String, Object?> toOpenApiSpec() => {'minItems': min};
}

/// {@template max_items_list_validator}
/// Validator that checks if a [List] has at most a certain number of items
///
/// Equivalent of calling `list.length <= max`
/// {@endtemplate}
class ListMaxItemsConstraint<T> extends Constraint<List<T>>
    with Validator<List<T>>, OpenApiSpec<List<T>> {
  /// The maximum number of items
  final int max;

  /// {@macro max_items_list_validator}
  const ListMaxItemsConstraint(this.max)
      : super(
          key: 'list_max_items',
          description: 'List must have at most $max items',
        );

  @override
  bool isValid(List<T> value) => value.length <= max;

  @override
  String buildMessage(List<T> value) {
    return 'The list contains ${value.length} items, which exceeds the allowed maximum of $max.';
  }

  @override
  Map<String, Object?> toOpenApiSpec() => {'maxItems': max};
}

/// {@template min_num_validator}
/// Validates that the input number is greater than or equal to a minimum value.
///
/// The [min] parameter specifies the minimum allowed value.
/// The [exclusive] parameter determines whether the minimum value itself is allowed:
/// - If false (default), values greater than or equal to min are valid
/// - If true, only values strictly greater than min are valid
/// {@endtemplate}
class NumberMinConstraint<T extends num> extends Constraint<T>
    with Validator<T>, OpenApiSpec<T> {
  /// The minimum value
  final T min;

  /// Whether the minimum value is exclusive
  final bool exclusive;

  /// {@macro min_num_validator}
  const NumberMinConstraint(this.min, {bool? exclusive})
      : exclusive = exclusive ?? false,
        super(
          key: 'number_min',
          description: 'Must be greater than or equal to $min',
        );
  @override
  bool isValid(num value) => exclusive ? value > min : value >= min;

  @override
  String buildMessage(T value) {
    return exclusive
        ? 'The number ($value) is too low; it must be greater than ($min).'
        : 'The number ($value) is too low; it must be at least ($min).';
  }

  @override
  Map<String, Object?> toOpenApiSpec() => {
        'minimum': min,
        if (exclusive) 'exclusiveMinimum': exclusive,
      };
}

/// {@template multiple_of_num_validator}
/// Validates that the input number is a multiple of a given value.
/// {@endtemplate}
class NumberMultipleOfConstraint<T extends num> extends Constraint<T>
    with Validator<T>, OpenApiSpec<T> {
  /// The multiple
  final T multiple;

  /// {@macro multiple_of_num_validator}
  const NumberMultipleOfConstraint(this.multiple)
      : super(
          key: 'number_multiple_of',
          description: 'Must be a multiple of $multiple',
        );

  @override
  bool isValid(num value) => value % multiple == 0;

  @override
  String buildMessage(T value) {
    return 'The number ($value) is not a multiple of ($multiple). The quotient is (${value / multiple}), the remainder is (${value % multiple}).';
  }

  @override
  Map<String, Object?> toOpenApiSpec() => {'multipleOf': multiple};
}

/// {@template max_num_validator}
/// Validates that the input number is less than a maximum value.
///
/// The [max] parameter specifies the maximum allowed value.
/// The [exclusive] parameter determines whether the maximum value itself is allowed:
/// - If true (default), only values strictly less than max are valid
/// - If false, values less than or equal to max are valid
/// {@endtemplate}
class NumberMaxConstraint<T extends num> extends Constraint<T>
    with Validator<T>, OpenApiSpec<T> {
  /// The maximum value
  final T max;

  /// Whether the maximum value is exclusive
  final bool exclusive;

  /// {@macro max_num_validator}
  const NumberMaxConstraint(this.max, {bool? exclusive})
      : exclusive = exclusive ?? false,
        super(
          key: 'number_max',
          description: 'Must be less than or equal to $max',
        );

  @override
  bool isValid(num value) => exclusive ? value < max : value <= max;

  @override
  String buildMessage(T value) {
    return exclusive
        ? 'The number ($value) exceeds the limit; it must be less than ($max).'
        : 'The number ($value) exceeds the maximum allowed of ($max).';
  }

  @override
  Map<String, Object?> toOpenApiSpec() => {
        'maximum': max,
        if (exclusive) 'exclusiveMaximum': exclusive,
      };
}

/// {@template range_num_validator}
/// Validates that the input number is between a minimum and maximum value.
///
/// The [min] parameter specifies the minimum allowed value.
/// The [max] parameter specifies the maximum allowed value.
/// The [exclusive] parameter determines whether the minimum and maximum values themselves are allowed:
/// - If true (default), only values strictly between min and max are valid
/// - If false, values between min and max (inclusive) are valid
/// {@endtemplate}
class NumberRangeConstraint<T extends num> extends Constraint<T>
    with Validator<T>, OpenApiSpec<T> {
  /// The minimum value
  final T min;

  /// The maximum value
  final T max;

  /// Whether the minimum and maximum values are exclusive
  final bool exclusive;

  /// {@macro range_num_validator}
  const NumberRangeConstraint(this.min, this.max, {bool? exclusive})
      : exclusive = exclusive ?? false,
        super(
          key: 'number_range',
          description: 'Must be between $min and $max (inclusive)',
        );

  @override
  bool isValid(num value) =>
      exclusive ? value > min && value < max : value >= min && value <= max;

  @override
  String buildMessage(T value) {
    return 'The number ($value) is outside the allowed range ($min to $max).';
  }

  @override
  Map<String, Object?> toOpenApiSpec() => {
        'minimum': min,
        'maximum': max,
        if (exclusive) 'exclusiveMinimum': exclusive,
        if (exclusive) 'exclusiveMaximum': exclusive,
      };
}

/// {@template object_min_properties_validator}
/// Validator that checks if a [Map] has at least a minimum number of properties
///
/// Equivalent of calling `map.length >= min`
/// {@endtemplate}
class ObjectMinPropertiesConstraint extends Constraint<MapValue>
    with Validator<MapValue>, OpenApiSpec<MapValue> {
  /// The minimum number of properties required
  final int min;

  /// {@macro object_min_properties_validator}
  const ObjectMinPropertiesConstraint({required this.min})
      : super(
          key: 'object_min_properties',
          description: 'Object must have at least $min properties',
        );

  @override
  bool isValid(MapValue value) => value.length >= min;

  @override
  String buildMessage(MapValue value) {
    return 'The object has ${value.length} properties, which is less than the required minimum of $min.';
  }

  @override
  Map<String, Object?> toOpenApiSpec() => {'minProperties': min};
}

/// {@template object_max_properties_validator}
/// Validator that checks if a [Map] has at most a maximum number of properties
///
/// Equivalent of calling `map.length <= max`
/// {@endtemplate}
class ObjectMaxPropertiesConstraint extends Constraint<MapValue>
    with Validator<MapValue>, OpenApiSpec<MapValue> {
  /// The maximum number of properties allowed
  final int max;

  /// {@macro object_max_properties_validator}
  const ObjectMaxPropertiesConstraint({required this.max})
      : super(
          key: 'object_max_properties',
          description: 'Object must have at most $max properties',
        );

  @override
  bool isValid(MapValue value) => value.length <= max;

  @override
  String buildMessage(MapValue value) {
    return 'The object has ${value.length} properties, exceeding the allowed maximum of $max.';
  }

  @override
  Map<String, Object?> toOpenApiSpec() => {'maxProperties': max};
}

/// {@template unallowed_property_constraint_error}
/// Validator that checks if a [Map] has unallowed properties
/// {@endtemplate}
class ObjectNoAdditionalPropertiesConstraint extends Constraint<MapValue>
    with Validator<MapValue> {
  final ObjectSchema schema;

  /// {@macro unallowed_property_constraint_error}
  ObjectNoAdditionalPropertiesConstraint(this.schema)
      : super(
          key: 'object_no_additional_properties',
          description:
              'Unallowed additional properties: ${schema.getProperties().keys}',
        );

  Iterable<String> _getUnallowedProperties(MapValue value) =>
      value.keys.toSet().difference(schema.getProperties().keys.toSet());

  @override
  bool isValid(MapValue value) => schema.getAllowsAdditionalProperties()
      ? true
      : _getUnallowedProperties(value).isEmpty;

  @override
  String buildMessage(MapValue value) {
    final unallowedKeys = _getUnallowedProperties(value);

    return 'Unallowed properties: $unallowedKeys.';
  }
}

/// {@template property_required_constraint_error}
/// Validator that checks if a [Map] has required properties
/// {@endtemplate}
class ObjectRequiredPropertiesConstraint extends Constraint<MapValue>
    with Validator<MapValue> {
  /// The list of required keys
  final ObjectSchema schema;

  /// {@macro property_required_constraint_error}
  ObjectRequiredPropertiesConstraint(this.schema)
      : super(
          key: 'object_required_properties',
          description: 'Required properties: ${schema.getRequiredProperties()}',
        );

  @override
  bool isValid(MapValue value) {
    return value.keys.containsAll(schema.getRequiredProperties());
  }

  @override
  String buildMessage(MapValue value) {
    final missingKeys =
        schema.getRequiredProperties().toSet().difference(value.keys.toSet());

    return 'Missing required properties: $missingKeys.';
  }
}

/// Validates that schemas in a discriminated object are properly structured.
/// Each schema must include the discriminator key as a required property.
class ObjectDiscriminatorStructureConstraint
    extends Constraint<Map<String, ObjectSchema>>
    with Validator<Map<String, ObjectSchema>> {
  final String discriminatorKey;

  ObjectDiscriminatorStructureConstraint(this.discriminatorKey)
      : super(
          key: 'object_discriminator_structure',
          description:
              'All schemas must have "$discriminatorKey" as a required property',
        );

  /// Returns schemas missing the discriminator key in their properties
  List<String> _getSchemasWithMissingDiscriminator(
    Map<String, ObjectSchema> schemas,
  ) {
    return schemas.entries
        .where((entry) =>
            !entry.value.getProperties().containsKey(discriminatorKey))
        .map((entry) => entry.key)
        .toList();
  }

  /// Returns schemas where the discriminator is not a required property
  List<String> _getSchemasWithNotRequiredDiscriminator(
    Map<String, ObjectSchema> schemas,
  ) {
    return schemas.entries
        .where((entry) =>
            entry.value.getProperties().containsKey(discriminatorKey) &&
            !entry.value.getRequiredProperties().contains(discriminatorKey))
        .map((entry) => entry.key)
        .toList();
  }

  @override
  bool isValid(Map<String, ObjectSchema> value) {
    return _getSchemasWithMissingDiscriminator(value).isEmpty &&
        _getSchemasWithNotRequiredDiscriminator(value).isEmpty;
  }

  @override
  String buildMessage(Map<String, ObjectSchema> value) {
    final missing = _getSchemasWithMissingDiscriminator(value);
    final notRequired = _getSchemasWithNotRequiredDiscriminator(value);

    return '''
The discriminator key "$discriminatorKey" must be present and required in all schemas.
${missing.isNotEmpty ? '- Missing in: $missing\n' : ''}
${notRequired.isNotEmpty ? '- Not marked as required in: $notRequired' : ''}
''';
  }
}

/// Validates that a value has a valid discriminator that matches a known schema.
class ObjectDiscriminatorValueConstraint extends Constraint<MapValue>
    with Validator<MapValue> {
  final String discriminatorKey;
  final Map<String, ObjectSchema> schemas;

  ObjectDiscriminatorValueConstraint(this.discriminatorKey, this.schemas)
      : super(
          key: 'object_discriminator_value',
          description: 'Value must have a valid discriminator',
        );

  @override
  bool isValid(MapValue value) {
    // Check if discriminator key exists
    if (!value.containsKey(discriminatorKey)) {
      return false;
    }

    // Get the discriminator value
    final discriminatorValue = value[discriminatorKey];

    // Check if value is convertible to string and matches a schema
    return discriminatorValue != null &&
        schemas.containsKey(discriminatorValue.toString());
  }

  @override
  String buildMessage(MapValue value) {
    final discriminatorValue = value[discriminatorKey];
    final validSchemaKeys = schemas.keys.toList();

    return discriminatorValue != null
        ? 'The discriminator value "$discriminatorValue" is invalid. Allowed values: $validSchemaKeys.'
        : 'The discriminator field "$discriminatorKey" is missing.';
  }
}
