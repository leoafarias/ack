import 'package:ack/src/helpers.dart';
import 'package:ack/src/validation/constraint_validator.dart';
import 'package:ack/src/validation/schema_error.dart';
import 'package:meta/meta.dart';

import '../schemas/schema.dart';

/// Provides validation methods for [StringSchema].
extension StringSchemaValidatorExt on StringSchema {
  /// {@macro email_validator}
  StringSchema isEmail() => withConstraints([EmailStringValidator()]);

  /// {@macro hex_color_validator}
  StringSchema isHexColor() => withConstraints([HexColorStringValidator()]);

  /// {@macro is_empty_validator}
  StringSchema isEmpty() => withConstraints([const IsEmptyStringValidator()]);

  /// {@macro min_length_validator}
  StringSchema minLength(int min) =>
      withConstraints([MinLengthStringValidator(min)]);

  /// {@macro max_length_validator}
  StringSchema maxLength(int max) =>
      withConstraints([MaxLengthStringValidator(max)]);

  /// {@macro one_of_validator}
  StringSchema oneOf(List<String> values) =>
      withConstraints([OneOfStringValidator(values)]);

  /// {@macro not_one_of_validator}
  StringSchema notOneOf(List<String> values) =>
      withConstraints([NotOneOfStringValidator(values)]);

  /// {@macro enum_validator}
  StringSchema isEnum(List<String> values) =>
      withConstraints([EnumStringValidator(values)]);

  /// {@macro not_empty_validator}
  StringSchema isNotEmpty() =>
      withConstraints([const NotEmptyStringValidator()]);

  /// {@macro date_time_validator}
  StringSchema isDateTime() =>
      withConstraints([const DateTimeStringValidator()]);

  /// {@macro date_validator}
  StringSchema isDate() => withConstraints([const DateStringValidator()]);
}

extension NumSchemaValidatorExt<T extends num> on NumSchema<T> {
  /// {@macro min_num_validator}
  NumSchema<T> min(T min) => withConstraints([MinNumValidator(min)]);

  /// {@macro max_num_validator}
  NumSchema<T> max(T max) => withConstraints([MaxNumValidator(max)]);

  /// {@macro range_num_validator}
  NumSchema<T> range(T min, T max) =>
      withConstraints([RangeNumValidator(min, max)]);

  /// {@macro multiple_of_num_validator}
  NumSchema<T> multipleOf(T multiple) =>
      withConstraints([MultipleOfNumValidator(multiple)]);
}

/// {@template date_time_validator}
/// Validates that the input string can be parsed into a [DateTime] object.
///
/// Equivalent of calling `DateTime.tryParse(value) != null`
/// {@endtemplate}
class DateTimeStringValidator extends ConstraintValidator<String>
    with OpenAPiSpecOutput<String> {
  /// {@macro date_time_validator}
  const DateTimeStringValidator()
      : super(
          name: 'date_time',
          description: 'Must be a valid date time string',
        );

  @override
  bool isValid(String value) => DateTime.tryParse(value) != null;

  @override
  ConstraintError onError(String value) {
    return buildError(
      extra: {
        'expected_format': 'ISO 8601',
        'example': '2023-01-01T00:00:00.000Z',
      },
    );
  }

  @override
  Map<String, Object?> toSchema() => {'format': 'date-time'};

  @override
  String get errorTemplate =>
      'Invalid date format for {{ value }}. Expected format: {{ extra.expected_format }}. Example: {{ extra.example }}';
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
  ConstraintError onError(String value) {
    return buildError(
      extra: {'expected_format': 'YYYY-MM-DD', 'example': '2017-07-21'},
    );
  }

  @override
  Map<String, Object?> toSchema() => {'format': 'date'};

  @override
  String get errorTemplate =>
      'Invalid date format for {{ value }}. Expected format: {{ extra.expected_format }}. Example: {{ extra.example }}';
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
  ConstraintError onError(String value) {
    return buildError(
      extra: {
        'closest_match': findClosestStringMatch(value, enumValues),
        'enum_values': enumValues,
        'total_allowed_values': enumValues.length,
      },
    );
  }

  @override
  Map<String, Object?> toSchema() => {'enum': enumValues};

  @override
  String get errorTemplate =>
      'Value {{ value }} is not a valid enum value. Did you mean {{ extra.closest_match }}? Must be one of: {{ extra.enum_values }}';
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

/// {@template one_of_validator}
/// Validates that the input string exactly matches one of the allowed values
///
/// Uses a regex pattern to match the exact string against the allowed values
/// Example: For values ['a', 'b', 'c'], pattern will be '^(a|b|c)$'
/// {@endtemplate}
class OneOfStringValidator extends RegexPatternStringValidator {
  /// The allowed values
  final List<String> values;

  /// {@macro one_of_validator}
  OneOfStringValidator(this.values)
      : super(
          name: 'one_of',
          pattern: '^(${values.map((e) => RegExp.escape(e)).join('|')})\$',
          example: values.first,
        );

  @override
  bool isValid(String value) => values.contains(value);

  @override
  ConstraintError onError(String value) {
    return buildError(
      extra: {
        'allowed_values': values,
        'total_allowed_values': values.length,
        'closest_match': findClosestStringMatch(value, values),
      },
    );
  }

  @override
  String get errorTemplate =>
      'Value {{ value }} is not allowed. Must be one of: {{ allowed_values }}';
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
  ConstraintError onError(String value) {
    return buildError(
      extra: {
        'disallowed_values': disallowedValues,
        'total_disallowed_values': disallowedValues.length,
      },
    );
  }

  @override
  String get errorTemplate =>
      'Value {{ value }} is not allowed. Must NOT be one of: {{ extra.disallowed_values }}';
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
  ConstraintError onError(String value) {
    return buildError(extra: {'value_length': value.length});
  }

  @override
  String get errorTemplate => 'String must not be empty';
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
      throw ArgumentError(r'Pattern must start with ^ and end with $');
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
  ConstraintError onError(String value) {
    return buildError(
      extra: {'pattern_name': name, 'pattern': pattern, 'example': example},
    );
  }

  @override
  Map<String, Object?> toMap() => {'pattern': pattern, 'name': name};

  @override
  Map<String, Object?> toSchema() => {'pattern': pattern, 'name': name};

  @override
  String get errorTemplate =>
      'Invalid {{ extra.pattern_name }} format. The string must match the pattern: {{ extra.pattern }}. Example: {{ extra.example }}';
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
  ConstraintError onError(String value) {
    return buildError(extra: {'value_length': value.length});
  }

  @override
  String get errorTemplate => 'String must be empty instead of {{ value }}';
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
  ConstraintError onError(String value) {
    return buildError(extra: {'value_length': value.length, 'min': min});
  }

  @override
  Map<String, Object?> toSchema() => {'minLength': min};

  @override
  String get errorTemplate =>
      'String must be at least {{ extra.min }} characters long instead of {{ extra.value_length }}';
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
  ConstraintError onError(String value) {
    return buildError(extra: {'value_length': value.length, 'max': max});
  }

  @override
  Map<String, Object?> toSchema() => {'maxLength': max};

  @override
  String get errorTemplate =>
      'String must be at most {{ extra.max }} characters long instead of {{ extra.value_length }}';
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
    return withConstraints([UniqueItemsListValidator()]);
  }

  /// {@macro min_items_list_validator}
  ///
  /// Example:
  /// ```dart
  /// final schema = Ack.list(Ack.string).minItems(2);
  /// ```
  ListSchema<T> minItems(int min) =>
      withConstraints([MinItemsListValidator(min)]);

  /// {@macro max_items_list_validator}
  ///
  /// Example:
  /// ```dart
  /// final schema = Ack.list(Ack.string).maxItems(3);
  /// ```
  ListSchema<T> maxItems(int max) =>
      withConstraints([MaxItemsListValidator(max)]);
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
  ConstraintError onError(List<T> value) {
    final nonUniqueValues = value.duplicates;

    return buildError(
      extra: {'value': value, 'duplicates': nonUniqueValues},
    );
  }

  @override
  Map<String, Object?> toSchema() => {'uniqueItems': true};

  @override
  String get errorTemplate =>
      'List should not contain duplicates: These items are repeated: {{ extra.duplicates }}';
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
  ConstraintError onError(List<T> value) {
    return buildError(
      extra: {'value': value, 'value_length': value.length, 'min': min},
    );
  }

  @override
  Map<String, Object?> toSchema() => {'minItems': min};

  @override
  String get errorTemplate =>
      'List length {{ extra.value_length }} is less than the minimum required length: {{ extra.min }}';
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
  ConstraintError onError(List<T> value) {
    return buildError(
      extra: {'value': value, 'value_length': value.length, 'max': max},
    );
  }

  @override
  Map<String, Object?> toSchema() => {'maxItems': max};

  @override
  String get errorTemplate =>
      'List length {{ extra.value_length }} is greater than the maximum required length: {{ extra.max }}';
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
  ConstraintError onError(num value) {
    return buildError(
      extra: {'value': value, 'min': min, 'exclusive': exclusive},
    );
  }

  @override
  Map<String, Object?> toSchema() => {
        'minimum': min,
        if (exclusive) 'exclusiveMinimum': exclusive,
      };

  @override
  String get errorTemplate => exclusive
      ? 'Value {{ extra.value }} is not greater than the minimum required value of {{ extra.min }}. Please provide a number greater than {{ extra.min }}.'
      : 'Value {{ extra.value }} is less than the minimum required value of {{ extra.min }}. Please provide a number greater than or equal to {{ extra.min }}.';
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
  ConstraintError onError(num value) {
    return buildError(
      extra: {
        'value': value,
        'multiple': multiple,
        'quotient': value / multiple,
        'remainder': value % multiple,
      },
    );
  }

  @override
  Map<String, Object?> toSchema() => {'multipleOf': multiple};

  @override
  String get errorTemplate =>
      'Value {{ extra.value }} is not a multiple of {{ extra.multiple }}.';
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
  ConstraintError onError(num value) {
    return buildError(
      extra: {'value': value, 'max': max, 'exclusive': exclusive},
    );
  }

  @override
  Map<String, Object?> toSchema() => {
        'maximum': max,
        if (exclusive) 'exclusiveMaximum': exclusive,
      };

  @override
  String get errorTemplate => exclusive
      ? 'Value {{ extra.value }} must be strictly less than {{ extra.max }}.'
      : 'Value {{ extra.value }} exceeds the maximum allowed value of {{ extra.max }}.';
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
  ConstraintError onError(num value) {
    return buildError(
      extra: {'value': value, 'min': min, 'max': max, 'exclusive': exclusive},
    );
  }

  @override
  Map<String, Object?> toSchema() => {
        'minimum': min,
        'maximum': max,
        if (exclusive) 'exclusiveMinimum': exclusive,
        if (exclusive) 'exclusiveMaximum': exclusive,
      };

  @override
  String get errorTemplate =>
      'Value {{ extra.value }} must be between {{ extra.min }} and {{ extra.max }} ${exclusive ? "(exclusive)" : ""}';
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

  /// {@macro object_min_properties_validator}
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

  /// {@macro object_max_properties_validator}
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

/// {@template unallowed_property_constraint_error}
/// Validator that checks if a [Map] has unallowed properties
/// {@endtemplate}
class UnallowedPropertyConstraintError extends ConstraintValidator<MapValue> {
  /// The key of the unallowed property
  final String key;

  /// {@macro unallowed_property_constraint_error}
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

/// {@template property_required_constraint_error}
/// Validator that checks if a [Map] has required properties
/// {@endtemplate}
class PropertyRequiredConstraintError extends ConstraintValidator<MapValue> {
  /// The key of the required property
  final String key;

  /// The list of required keys
  final List<String> requiredKeys;

  /// {@macro property_required_constraint_error}
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
