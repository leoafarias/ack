part of '../schema.dart';

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

/// {@template date_time_validator}
/// Validates that the input string can be parsed into a [DateTime] object.
///
/// Equivalent of calling `DateTime.tryParse(value) != null`
/// {@endtemplate}
class DateTimeStringValidator extends ConstraintValidator<String>
    with OpenAPiSpecOutput<String> {
  const DateTimeStringValidator()
      : super(
          name: 'date_time',
          description: 'Must be a valid date time string',
        );

  @override
  bool isValid(String value) {
    final dateTime = DateTime.tryParse(value);

    return dateTime != null;
  }

  @override
  ConstraintError onError(String value) {
    return buildError(
      template:
          'Invalid date format for {{ value }}. Expected format: {{ expected_format }}. Example: {{ example }}',
      context: {
        'value': value,
        'expected_format': 'ISO 8601',
        'example': '2023-01-01T00:00:00.000Z',
      },
    );
  }

  @override
  Map<String, Object?> toSchema() => {'format': 'date-time'};
}

/// {@template date_validator}
/// Validates that the input string can be parsed into a `2017-07-21
/// {@endtemplate}
class DateStringValidator extends ConstraintValidator<String>
    with OpenAPiSpecOutput<String> {
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
      template:
          'Invalid date format for {{ value }}. Expected format: {{ expected_format }}. Example: {{ example }}',
      context: {
        'value': value,
        'expected_format': 'YYYY-MM-DD',
        'example': '2017-07-21',
      },
    );
  }

  @override
  Map<String, Object?> toSchema() => {'format': 'date'};
}

/// {@template enum_validator}
/// Validates that the input string is one of the allowed enum values
///
/// Equivalent of calling `enumValues.contains(value)`
/// {@endtemplate}
class EnumStringValidator extends ConstraintValidator<String>
    with OpenAPiSpecOutput<String> {
  final List<String> enumValues;
  const EnumStringValidator(this.enumValues)
      : super(name: 'enum', description: 'Must be one of: $enumValues}');

  @override
  bool isValid(String value) => enumValues.contains(value);

  @override
  ConstraintError onError(String value) {
    return buildError(
      template:
          'Value {{ value }} is not a valid enum value. Did you mean {{ closest_match }}? Must be one of: {{ enum_values }}',
      context: {
        'value': value,
        'closest_match': findClosestStringMatch(value, enumValues),
        'enum_values': enumValues,
        'total_allowed_values': enumValues.length,
      },
    );
  }

  @override
  Map<String, Object?> toSchema() => {'enum': enumValues};
}

/// {@template email_validator}
/// Validates that the input string matches an email pattern
///
/// Uses regex pattern: `^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$`
/// {@endtemplate}
class EmailStringValidator extends RegexPatternStringValidator {
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
  final List<String> values;
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
      template:
          'Value {{ value }} is not allowed. Did you mean {{ closest_match }}? Must be one of: {{ allowed_values }}',
      context: {
        'value': value,
        'allowed_values': values,
        'total_allowed_values': values.length,
        'closest_match': findClosestStringMatch(value, values),
      },
    );
  }
}

/// {@template not_one_of_validator}
/// Validates that the input string is not one of the disallowed values
///
/// Uses a regex pattern to match the exact string against the disallowed values
/// Example: For values ['a', 'b', 'c'], pattern will be '^(?!a|b|c).*$'
/// {@endtemplate}
class NotOneOfStringValidator extends RegexPatternStringValidator {
  final List<String> values;
  NotOneOfStringValidator(this.values)
      : super(
          name: 'not_one_of',
          pattern: '^(?!${values.map((e) => RegExp.escape(e)).join('|')}).*\$',
          example: 'Any value except: $values',
        );

  @override
  bool isValid(String value) => !values.contains(value);

  @override
  ConstraintError onError(String value) {
    return buildError(
      template:
          'Value {{ value }} is not allowed. Must NOT be one of: {{ disallowed_values }}',
      context: {
        'value': value,
        'disallowed_values': values,
        'total_disallowed_values': values.length,
      },
    );
  }
}

/// {@template not_empty_validator}
/// Validates that the input string is not empty
///
/// Equivalent of calling `value.isNotEmpty`
/// {@endtemplate}
class NotEmptyStringValidator extends ConstraintValidator<String> {
  const NotEmptyStringValidator()
      : super(name: 'not_empty', description: 'String cannot be empty');

  @override
  bool isValid(String value) => value.isNotEmpty;

  @override
  ConstraintError onError(String value) {
    return buildError(
      template: 'Value of type String cannot be empty.',
      context: {'value': value, 'value_length': value.length},
    );
  }
}

/// Base class for regex-based string validators
class RegexPatternStringValidator extends ConstraintValidator<String>
    with OpenAPiSpecOutput<String> {
  final String pattern;
  final String example;
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
      template:
          'Invalid {{ pattern_name }} format. The string must match the pattern: {{ pattern }}. Example: {{ example }}',
      context: {
        'pattern_name': name,
        'pattern': pattern,
        'value': value,
        'example': example,
      },
    );
  }

  @override
  Map<String, Object?> toMap() => {'pattern': pattern, 'name': name};

  @override
  Map<String, Object?> toSchema() => {'pattern': pattern, 'name': name};
}

/// {@template is_empty_validator}
/// Validates that the input string is empty
///
/// Equivalent of calling `value.isEmpty`
/// {@endtemplate}
class IsEmptyStringValidator extends ConstraintValidator<String> {
  const IsEmptyStringValidator()
      : super(name: 'is_empty', description: 'String must be empty');

  @override
  bool isValid(String value) => value.isEmpty;

  @override
  ConstraintError onError(String value) {
    return buildError(
      template: 'Value of type string must be empty. Instead got: {{ value }}',
      context: {'value': value, 'value_length': value.length},
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
  final int min;
  const MinLengthStringValidator(this.min)
      : super(
          name: 'min_length',
          description: 'String must be at least $min characters long',
        );

  @override
  bool isValid(String value) => value.length >= min;

  @override
  ConstraintError onError(String value) {
    return buildError(
      template:
          'Value {{ value }} is too short. Has the length of {{ value_length }} characters. Minimum length is {{ min_length }} characters',
      context: {
        'value': value,
        'value_length': value.length,
        'min_length': min,
      },
    );
  }

  @override
  Map<String, Object?> toSchema() => {'minLength': min};
}

/// {@template max_length_validator}
/// Validates that the input string length is at most a certain value
///
/// Equivalent of calling `value.length <= max`
/// {@endtemplate}
class MaxLengthStringValidator extends ConstraintValidator<String>
    with OpenAPiSpecOutput<String> {
  final int max;
  const MaxLengthStringValidator(this.max)
      : super(
          name: 'max_length',
          description: 'String must be at most $max characters long',
        );

  @override
  bool isValid(String value) => value.length <= max;

  @override
  ConstraintError onError(String value) {
    return buildError(
      template:
          'Value {{ value }} is too long. Has the length of {{ value_length }} characters. Maximum length is {{ max_length }} characters',
      context: {
        'value': value,
        'value_length': value.length,
        'max_length': max,
      },
    );
  }

  @override
  Map<String, Object?> toSchema() => {'maxLength': max};
}
