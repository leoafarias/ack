part of '../schema.dart';

extension IntSchemaValidatorExt on IntegerSchema {
  /// {@macro max_num_validator}
  IntegerSchema maxValue(int max, {bool? exclusive}) =>
      withConstraints([MaxNumValidator<int>(max, exclusive: exclusive)]);

  /// {@macro min_num_validator}
  IntegerSchema minValue(int min, {bool? exclusive}) =>
      withConstraints([MinNumValidator<int>(min, exclusive: exclusive)]);

  /// {@macro range_num_validator}
  IntegerSchema range(int min, int max, {bool? exclusive}) =>
      withConstraints([RangeNumValidator<int>(min, max, exclusive: exclusive)]);

  /// {@macro multiple_of_num_validator}
  IntegerSchema multipleOf(int multiple) =>
      withConstraints([MultipleOfNumValidator<int>(multiple)]);
}

extension DoubleSchemaValidatorExt on DoubleSchema {
  /// {@macro max_num_validator}
  DoubleSchema maxValue(double max, {bool? exclusive}) =>
      withConstraints([MaxNumValidator<double>(max, exclusive: exclusive)]);

  /// {@macro min_num_validator}
  DoubleSchema minValue(double min, {bool? exclusive}) =>
      withConstraints([MinNumValidator<double>(min, exclusive: exclusive)]);

  /// {@macro range_num_validator}
  DoubleSchema range(double min, double max, {bool? exclusive}) =>
      withConstraints(
        [RangeNumValidator<double>(min, max, exclusive: exclusive)],
      );

  /// {@macro multiple_of_num_validator}
  DoubleSchema multipleOf(double multiple) =>
      withConstraints([MultipleOfNumValidator<double>(multiple)]);
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
  final T min;
  final bool exclusive;
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

// Multiple of
class MultipleOfNumValidator<T extends num> extends ConstraintValidator<T>
    with OpenAPiSpecOutput<T> {
  final T multiple;
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
  final T max;
  final bool exclusive;
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
  final T min;
  final T max;
  final bool exclusive;
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
