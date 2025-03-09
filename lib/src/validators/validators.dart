import 'dart:convert';

import 'package:ack/src/helpers.dart';
import 'package:ack/src/validation/constraint_validator.dart';
import 'package:ack/src/validation/schema_error.dart';
import 'package:meta/meta.dart';

import '../schemas/schema.dart';

/// Provides validation methods for [StringSchema].
extension StringSchemaValidatorExt on StringSchema {
  /// {@macro email_validator}
  StringSchema isEmail() => withValidators([EmailStringValidator()]);

  /// {@macro hex_color_validator}
  StringSchema isHexColor() => withValidators([HexColorStringValidator()]);

  /// {@macro is_empty_validator}
  StringSchema isEmpty() => withValidators([const IsEmptyStringValidator()]);

  /// {@macro min_length_validator}
  StringSchema minLength(int min) =>
      withValidators([MinLengthStringValidator(min)]);

  /// {@macro max_length_validator}
  StringSchema maxLength(int max) =>
      withValidators([MaxLengthStringValidator(max)]);

  /// {@macro not_one_of_validator}
  StringSchema notOneOf(List<String> values) =>
      withValidators([NotOneOfStringValidator(values)]);

  /// {@macro is_json_validator}
  StringSchema isJson() => withValidators([const IsJsonStringValidator()]);

  /// {@macro enum_validator}
  StringSchema isEnum(List<String> values) =>
      withValidators([EnumStringValidator(values)]);

  /// {@macro not_empty_validator}
  StringSchema isNotEmpty() =>
      withValidators([const NotEmptyStringValidator()]);

  /// {@macro date_time_validator}
  StringSchema isDateTime() =>
      withValidators([const StringDateTimeValidator()]);

  /// {@macro date_validator}
  StringSchema isDate() => withValidators([const DateStringValidator()]);
}

extension NumSchemaValidatorExt<T extends num> on NumSchema<T> {
  /// {@macro min_num_validator}
  NumSchema<T> min(T min) => withValidators([MinNumValidator(min)]);

  /// {@macro max_num_validator}
  NumSchema<T> max(T max) => withValidators([MaxNumValidator(max)]);

  /// {@macro range_num_validator}
  NumSchema<T> range(T min, T max) =>
      withValidators([RangeNumValidator(min, max)]);

  /// {@macro multiple_of_num_validator}
  NumSchema<T> multipleOf(T multiple) =>
      withValidators([MultipleOfNumValidator(multiple)]);
}

/// {@template date_time_validator}
/// Validates that the input string can be parsed into a [DateTime] object.
///
/// Equivalent of calling `DateTime.tryParse(value) != null`
/// {@endtemplate}
class StringDateTimeValidator extends ConstraintValidator<String>
    with OpenAPiSpecOutput<String> {
  /// {@macro date_time_validator}
  const StringDateTimeValidator()
      : super(
          name: 'date_time',
          description: 'Must be a valid date time string',
        );

  @override
  bool isValid(String value) => DateTime.tryParse(value) != null;

  @override
  ConstraintError buildError(String value) {
    return ConstraintError(
      key: name,
      message:
          'The value "$value" is not a valid date time. Expected format: ISO 8601 (e.g., {{ example }}).',
    );
  }

  @override
  Map<String, Object?> topOpenApiSchema() => {'format': 'date-time'};
}

/// {@template date_validator}
/// Validates that the input string can be parsed into a `2017-07-21
/// {@endtemplate}
class DateStringValidator extends ConstraintValidator<String>
    with OpenAPiSpecOutput<String> {
  /// {@macro date_validator}
  const DateStringValidator()
      : super(
          name: 'date',
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
  ConstraintError buildError(String value) {
    return ConstraintError(
      key: name,
      message:
          'The value "$value" is not a valid date. Expected format: YYYY-MM-DD (e.g., 2017-07-21).',
    );
  }

  @override
  Map<String, Object?> topOpenApiSchema() => {'format': 'date'};
}

/// {@template enum_validator}
/// Validates that the input string is one of the allowed enum values
///
/// Equivalent of calling `enumValues.contains(value)`
/// {@endtemplate}
class EnumStringValidator extends ConstraintValidator<String>
    with OpenAPiSpecOutput<String> {
  /// The allowed enum values
  final List<String> enumValues;

  /// {@macro enum_validator}
  const EnumStringValidator(this.enumValues)
      : super(name: 'enum', description: 'Must be one of: $enumValues}');

  @override
  bool isValid(String value) => enumValues.contains(value);

  @override
  ConstraintError buildError(String value) {
    final closestMatch = findClosestStringMatch(value, enumValues);
    final closestMatchMessage =
        closestMatch.isTruthy ? '(Closest match: "${closestMatch!}")' : '';

    return ConstraintError(
      key: name,
      message:
          'Invalid value "$value". Allowed values are: $enumValues. $closestMatchMessage',
    );
  }

  @override
  Map<String, Object?> topOpenApiSchema() => {'enum': enumValues};
}

/// {@template email_validator}
/// Validates that the input string matches an email pattern
///
/// Uses regex pattern: `^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$`
/// {@endtemplate}
class EmailStringValidator extends RegexPatternStringValidator {
  /// {@macro email_validator}
  EmailStringValidator()
      : super(
          name: 'email',
          pattern: r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
          example: 'example@domain.com',
        );
}

/// {@template hex_color_validator}
/// Validates that the input string matches a hex color pattern
///
/// Uses regex pattern: `^#?([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$`
/// {@endtemplate}
class HexColorStringValidator extends RegexPatternStringValidator {
  /// {@macro hex_color_validator}
  HexColorStringValidator()
      : super(
          name: 'hex_color',
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
class NotOneOfStringValidator extends RegexPatternStringValidator {
  /// The disallowed values
  final List<String> disallowedValues;

  /// {@macro not_one_of_validator}
  NotOneOfStringValidator(this.disallowedValues)
      : super(
          name: 'not_one_of',
          pattern:
              '^(?!${disallowedValues.map((e) => RegExp.escape(e)).join('|')}).*\$',
          example: 'Any value except: $disallowedValues',
        );

  @override
  bool isValid(String value) => !disallowedValues.contains(value);

  @override
  ConstraintError buildError(String value) {
    return ConstraintError(
      key: name,
      message:
          'The value "$value" is not allowed. Disallowed values: $disallowedValues.',
    );
  }

  @override
  String get errorMessage =>
      'The value "{{ value }}" is not allowed. Disallowed values: {{ disallowed_values }}.';
}

/// {@template not_empty_validator}
/// Validates that the input string is not empty
///
/// Equivalent of calling `value.isNotEmpty`
/// {@endtemplate}
class NotEmptyStringValidator extends ConstraintValidator<String> {
  /// {@macro not_empty_validator}
  const NotEmptyStringValidator()
      : super(name: 'not_empty', description: 'String cannot be empty');

  @override
  bool isValid(String value) => value.isNotEmpty;

  @override
  ConstraintError buildError(String value) {
    return ConstraintError(
      key: name,
      message: 'The string must not be empty.',
    );
  }
}

/// {@template is_json_validator}
/// Validates that the input string is a valid JSON string
///
/// Equivalent of calling `isJsonValue(value)`
/// {@endtemplate}
class IsJsonStringValidator extends ConstraintValidator<String> {
  /// {@macro is_json_string_validator}
  const IsJsonStringValidator()
      : super(name: 'is_json', description: 'Must be a valid JSON string');

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
  ConstraintError buildError(String value) {
    return ConstraintError(
      key: name,
      message: 'The value "$value" is not valid JSON.',
    );
  }
}

/// Base class for regex-based string validators
class RegexPatternStringValidator extends ConstraintValidator<String>
    with OpenAPiSpecOutput<String> {
  /// The regex pattern to match
  final String pattern;

  /// An example value that matches the pattern
  final String example;

  /// {@macro regex_pattern_string_validator}
  RegexPatternStringValidator({
    required super.name,
    required this.pattern,
    required this.example,
  }) : super(description: 'Must match the pattern: $name. Example $example') {
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
  ConstraintError buildError(String value) {
    return ConstraintError(
      key: name,
      message:
          'The value "$value" does not match the required pattern for $name. Expected format: "$example".',
    );
  }

  @override
  Map<String, Object?> toMap() => {'pattern': pattern, 'name': name};

  @override
  Map<String, Object?> topOpenApiSchema() => {'pattern': pattern, 'name': name};
}

/// {@template is_empty_validator}
/// Validates that the input string is empty
///
/// Equivalent of calling `value.isEmpty`
/// {@endtemplate}
class IsEmptyStringValidator extends ConstraintValidator<String> {
  /// {@macro is_empty_validator}
  const IsEmptyStringValidator()
      : super(name: 'is_empty', description: 'String must be empty');

  @override
  bool isValid(String value) => value.isEmpty;

  @override
  ConstraintError buildError(String value) {
    return ConstraintError(
      key: name,
      message: 'The string must be empty. Got: "$value"',
    );
  }
}

/// {@template min_length_validator}
/// Validates that the input string length is at least a certain value
///
/// Equivalent of calling `value.length >= min`
/// {@endtemplate}
class MinLengthStringValidator extends ConstraintValidator<String>
    with OpenAPiSpecOutput<String> {
  /// The minimum length
  final int min;

  /// {@macro min_length_validator}
  const MinLengthStringValidator(this.min)
      : super(
          name: 'min_length',
          description: 'String must be at least $min characters long',
        );

  @override
  bool isValid(String value) => value.length >= min;

  @override
  ConstraintError buildError(String value) {
    return ConstraintError(
      key: name,
      message:
          'The string length (${value.length}) is too short; it must be at least ($min) characters.',
    );
  }

  @override
  Map<String, Object?> topOpenApiSchema() => {'minLength': min};
}

/// {@template max_length_validator}
/// Validates that the input string length is at most a certain value
///
/// Equivalent of calling `value.length <= max`
/// {@endtemplate}
class MaxLengthStringValidator extends ConstraintValidator<String>
    with OpenAPiSpecOutput<String> {
  /// The maximum length
  final int max;

  /// {@macro max_length_validator}
  const MaxLengthStringValidator(this.max)
      : super(
          name: 'max_length',
          description: 'String must be at most $max characters long',
        );

  @override
  bool isValid(String value) => value.length <= max;

  @override
  @visibleForTesting
  ConstraintError buildError(String value) {
    return ConstraintError(
      key: name,
      message:
          'The string length (${value.length}) exceeds the maximum allowed of ($max) characters.',
    );
  }

  @override
  Map<String, Object?> topOpenApiSchema() => {'maxLength': max};
}

/// Provides validation methods for [ListSchema].
extension ListSchemaValidatorsExt<T extends Object> on ListSchema<T> {
  /// {@macro unique_items_list_validator}
  ///
  /// Example:
  /// ```dart
  /// final schema = Ack.list(Ack.string).uniqueItems();
  /// ```
  ListSchema<T> uniqueItems() {
    return withValidators([UniqueItemsListValidator()]);
  }

  /// {@macro min_items_list_validator}
  ///
  /// Example:
  /// ```dart
  /// final schema = Ack.list(Ack.string).minItems(2);
  /// ```
  ListSchema<T> minItems(int min) =>
      withValidators([MinItemsListValidator(min)]);

  /// {@macro max_items_list_validator}
  ///
  /// Example:
  /// ```dart
  /// final schema = Ack.list(Ack.string).maxItems(3);
  /// ```
  ListSchema<T> maxItems(int max) =>
      withValidators([MaxItemsListValidator(max)]);
}

/// {@template unique_items_list_validator}
/// Validator that checks if a [List] has unique items
///
/// Equivalent of calling `list.toSet().length == list.length`
/// {@endtemplate}
class UniqueItemsListValidator<T extends Object>
    extends ConstraintValidator<List<T>> with OpenAPiSpecOutput<List<T>> {
  /// {@macro unique_items_list_validator}
  const UniqueItemsListValidator()
      : super(
          name: 'unique_items',
          description: 'List items must be unique',
        );

  @override
  bool isValid(List<T> value) => value.duplicates.isEmpty;

  @override
  ConstraintError buildError(List<T> value, {variables}) {
    final nonUniqueValues = value.duplicates;

    return ConstraintError(
      key: name,
      message:
          'The list contains duplicate items: $nonUniqueValues. All items must be unique.',
    );
  }

  @override
  Map<String, Object?> topOpenApiSchema() => {'uniqueItems': true};
}

/// {@template min_items_list_validator}
/// Validator that checks if a [List] has at least a certain number of items
///
/// Equivalent of calling `list.length >= min`
/// {@endtemplate}
class MinItemsListValidator<T extends Object>
    extends ConstraintValidator<List<T>> with OpenAPiSpecOutput<List<T>> {
  /// The minimum number of items
  final int min;

  /// {@macro min_items_list_validator}
  const MinItemsListValidator(this.min)
      : super(
          name: 'min_items',
          description: 'List must have at least $min items',
        );

  @override
  bool isValid(List<T> value) => value.length >= min;

  @override
  ConstraintError buildError(List<T> value, {variables}) {
    return ConstraintError(
      key: name,
      message:
          'The list has only ${value.length} items; at least $min items are required.',
    );
  }

  @override
  Map<String, Object?> topOpenApiSchema() => {'minItems': min};
}

/// {@template max_items_list_validator}
/// Validator that checks if a [List] has at most a certain number of items
///
/// Equivalent of calling `list.length <= max`
/// {@endtemplate}
class MaxItemsListValidator<T> extends ConstraintValidator<List<T>>
    with OpenAPiSpecOutput<List<T>> {
  /// The maximum number of items
  final int max;

  /// {@macro max_items_list_validator}
  const MaxItemsListValidator(this.max)
      : super(
          name: 'max_items',
          description: 'List must have at most $max items',
        );

  @override
  bool isValid(List<T> value) => value.length <= max;

  @override
  ConstraintError buildError(List<T> value, {variables}) {
    return ConstraintError(
      key: name,
      message:
          'The list contains ${value.length} items, which exceeds the allowed maximum of $max.',
    );
  }

  @override
  Map<String, Object?> topOpenApiSchema() => {'maxItems': max};
}

/// {@template min_num_validator}
/// Validates that the input number is greater than or equal to a minimum value.
///
/// The [min] parameter specifies the minimum allowed value.
/// The [exclusive] parameter determines whether the minimum value itself is allowed:
/// - If false (default), values greater than or equal to min are valid
/// - If true, only values strictly greater than min are valid
/// {@endtemplate}
class MinNumValidator<T extends num> extends ConstraintValidator<T>
    with OpenAPiSpecOutput<T> {
  /// The minimum value
  final T min;

  /// Whether the minimum value is exclusive
  final bool exclusive;

  /// {@macro min_num_validator}
  const MinNumValidator(this.min, {bool? exclusive})
      : exclusive = exclusive ?? false,
        super(
          name: 'min_value',
          description: 'Must be greater than or equal to $min',
        );
  @override
  bool isValid(num value) => exclusive ? value > min : value >= min;

  @override
  ConstraintError buildError(T value, {variables}) {
    return ConstraintError(
      key: name,
      message: exclusive
          ? 'The number ($value) is too low; it must be greater than ($min).'
          : 'The number ($value) is too low; it must be at least ($min).',
    );
  }

  @override
  Map<String, Object?> topOpenApiSchema() => {
        'minimum': min,
        if (exclusive) 'exclusiveMinimum': exclusive,
      };
}

/// {@template multiple_of_num_validator}
/// Validates that the input number is a multiple of a given value.
/// {@endtemplate}
class MultipleOfNumValidator<T extends num> extends ConstraintValidator<T>
    with OpenAPiSpecOutput<T> {
  /// The multiple
  final T multiple;

  /// {@macro multiple_of_num_validator}
  const MultipleOfNumValidator(this.multiple)
      : super(
          name: 'multiple_of',
          description: 'Must be a multiple of $multiple',
        );

  @override
  bool isValid(num value) => value % multiple == 0;

  @override
  ConstraintError buildError(T value, {variables}) {
    return ConstraintError(
      key: name,
      message:
          'The number ($value) is not a multiple of ($multiple). The quotient is (${value / multiple}), the remainder is (${value % multiple}).',
    );
  }

  @override
  Map<String, Object?> topOpenApiSchema() => {'multipleOf': multiple};
}

/// {@template max_num_validator}
/// Validates that the input number is less than a maximum value.
///
/// The [max] parameter specifies the maximum allowed value.
/// The [exclusive] parameter determines whether the maximum value itself is allowed:
/// - If true (default), only values strictly less than max are valid
/// - If false, values less than or equal to max are valid
/// {@endtemplate}
class MaxNumValidator<T extends num> extends ConstraintValidator<T>
    with OpenAPiSpecOutput<T> {
  /// The maximum value
  final T max;

  /// Whether the maximum value is exclusive
  final bool exclusive;

  /// {@macro max_num_validator}
  const MaxNumValidator(this.max, {bool? exclusive})
      : exclusive = exclusive ?? false,
        super(
          name: 'max_value',
          description: 'Must be less than or equal to $max',
        );

  @override
  bool isValid(num value) => exclusive ? value < max : value <= max;

  @override
  ConstraintError buildError(T value, {variables}) {
    return ConstraintError(
      key: name,
      message: exclusive
          ? 'The number ($value) exceeds the limit; it must be less than ($max).'
          : 'The number ($value) exceeds the maximum allowed of ($max).',
    );
  }

  @override
  Map<String, Object?> topOpenApiSchema() => {
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
class RangeNumValidator<T extends num> extends ConstraintValidator<T>
    with OpenAPiSpecOutput<T> {
  /// The minimum value
  final T min;

  /// The maximum value
  final T max;

  /// Whether the minimum and maximum values are exclusive
  final bool exclusive;

  /// {@macro range_num_validator}
  const RangeNumValidator(this.min, this.max, {bool? exclusive})
      : exclusive = exclusive ?? false,
        super(
          name: 'range',
          description: 'Must be between $min and $max (inclusive)',
        );

  @override
  bool isValid(num value) =>
      exclusive ? value > min && value < max : value >= min && value <= max;

  @override
  ConstraintError buildError(T value, {variables}) {
    return ConstraintError(
      key: name,
      message:
          'The number ($value) is outside the allowed range ($min to $max).',
    );
  }

  @override
  Map<String, Object?> topOpenApiSchema() => {
        'minimum': min,
        'maximum': max,
        if (exclusive) 'exclusiveMinimum': exclusive,
        if (exclusive) 'exclusiveMaximum': exclusive,
      };
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
    return withValidators([MinPropertiesObjectValidator(min: min)]);
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
    return withValidators([MaxPropertiesObjectValidator(max: max)]);
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

  /// {@macro object_min_properties_validator}
  const MinPropertiesObjectValidator({required this.min})
      : super(
          name: 'object_min_properties',
          description: 'Object must have at least $min properties',
        );

  @override
  bool isValid(MapValue value) => value.length >= min;

  @override
  ConstraintError buildError(MapValue value, {variables}) {
    return ConstraintError(
      key: name,
      message:
          'The object has ${value.length} properties, which is less than the required minimum of $min.',
    );
  }

  @override
  Map<String, Object?> topOpenApiSchema() => {'minProperties': min};
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

  /// {@macro object_max_properties_validator}
  const MaxPropertiesObjectValidator({required this.max})
      : super(
          name: 'object_max_properties',
          description: 'Object must have at most $max properties',
        );

  @override
  bool isValid(MapValue value) => value.length <= max;

  @override
  ConstraintError buildError(MapValue value, {variables}) {
    return ConstraintError(
      key: name,
      message:
          'The object has ${value.length} properties, exceeding the allowed maximum of $max.',
    );
  }

  @override
  Map<String, Object?> topOpenApiSchema() => {'maxProperties': max};
}

/// {@template unallowed_property_constraint_error}
/// Validator that checks if a [Map] has unallowed properties
/// {@endtemplate}
class UnallowedPropertiesConstraintViolation
    extends ConstraintValidator<MapValue> {
  final ObjectSchema schema;

  /// {@macro unallowed_property_constraint_error}
  UnallowedPropertiesConstraintViolation(this.schema)
      : super(
          name: 'unallowed_property',
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
  ConstraintError buildError(MapValue value, {variables}) {
    final unallowedKeys = _getUnallowedProperties(value);

    return ConstraintError(
      key: name,
      message: 'Unallowed properties: $unallowedKeys.',
    );
  }
}

/// {@template property_required_constraint_error}
/// Validator that checks if a [Map] has required properties
/// {@endtemplate}
class PropertyRequiredConstraintViolation
    extends ConstraintValidator<MapValue> {
  /// The list of required keys
  final ObjectSchema schema;

  /// {@macro property_required_constraint_error}
  PropertyRequiredConstraintViolation(this.schema)
      : super(
          name: 'required_properties',
          description: 'Required properties: ${schema.getRequiredProperties()}',
        );

  @override
  bool isValid(MapValue value) {
    return value.keys.containsAll(schema.getRequiredProperties());
  }

  @override
  ConstraintError buildError(MapValue value, {variables}) {
    final missingKeys =
        schema.getRequiredProperties().toSet().difference(value.keys.toSet());

    return ConstraintError(
      key: name,
      message: 'Missing required properties: $missingKeys.',
    );
  }
}

/// Validates that schemas in a discriminated object are properly structured.
/// Each schema must include the discriminator key as a required property.
class DiscriminatorSchemaStructureViolation
    extends ConstraintValidator<Map<String, ObjectSchema>> {
  final String discriminatorKey;

  DiscriminatorSchemaStructureViolation(this.discriminatorKey)
      : super(
          name: 'discriminator_schema_structure',
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
  ConstraintError buildError(Map<String, ObjectSchema> value, {variables}) {
    final missing = _getSchemasWithMissingDiscriminator(value);
    final notRequired = _getSchemasWithNotRequiredDiscriminator(value);

    return ConstraintError(
      key: name,
      message: '''
The discriminator key "$discriminatorKey" must be present and required in all schemas.
${missing.isNotEmpty ? '- Missing in: $missing\n' : ''}
${notRequired.isNotEmpty ? '- Not marked as required in: $notRequired' : ''}
''',
    );
  }
}

/// Validates that a value has a valid discriminator that matches a known schema.
class DiscriminatorValueViolation extends ConstraintValidator<MapValue> {
  final String discriminatorKey;
  final Map<String, ObjectSchema> schemas;

  DiscriminatorValueViolation(this.discriminatorKey, this.schemas)
      : super(
          name: 'discriminator_value',
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
  ConstraintError buildError(MapValue value, {variables}) {
    final discriminatorValue = value[discriminatorKey];
    final validSchemaKeys = schemas.keys.toList();

    final message = discriminatorValue != null
        ? 'The discriminator value "$discriminatorValue" is invalid. Allowed values: $validSchemaKeys.'
        : 'The discriminator field "$discriminatorKey" is missing.';

    return ConstraintError(key: name, message: message);
  }
}
