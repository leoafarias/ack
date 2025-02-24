part of '../ack_base.dart';

final class DoubleSchema extends Schema<double> {
  const DoubleSchema({super.nullable, super.constraints, super.strict});

  @override
  DoubleSchema copyWith({
    bool? nullable,
    List<ConstraintValidator<double>>? constraints,
    bool? strict,
  }) {
    return DoubleSchema(
      nullable: nullable ?? _nullable,
      constraints: constraints ?? _constraints,
      strict: strict ?? _strict,
    );
  }
}

final class IntSchema extends Schema<int> {
  const IntSchema({super.nullable, super.constraints, super.strict});

  @override
  IntSchema copyWith({
    bool? nullable,
    List<ConstraintValidator<int>>? constraints,
    bool? strict,
  }) {
    return IntSchema(
      nullable: nullable ?? _nullable,
      constraints: constraints ?? _constraints,
      strict: strict ?? _strict,
    );
  }
}

extension DoubleSchemaExt<S extends Schema<double>> on S {
  S maxValue(num max) => copyWith(constraints: [MaxValueValidator(max)]) as S;

  S minValue(num min) => copyWith(constraints: [MinValueValidator(min)]) as S;

  S range(num min, num max) =>
      copyWith(constraints: [RangeValidator(min, max)]) as S;
}

extension IntSchemaExt<S extends Schema<int>> on S {
  S maxValue(num max) => copyWith(constraints: [MaxValueValidator(max)]) as S;

  S minValue(num min) => copyWith(constraints: [MinValueValidator(min)]) as S;

  S range(num min, num max) =>
      copyWith(constraints: [RangeValidator(min, max)]) as S;
}

class MinValueValidator<T extends num> extends ConstraintValidator<T> {
  final num min;
  const MinValueValidator(this.min);

  @override
  String get name => 'num_min_value';

  @override
  String get description => 'Must be greater than or equal to $min';

  @override
  bool check(num value) => value >= min;

  @override
  ConstraintError onError(num value) {
    return buildError(
      message: 'Value $value is less than the minimum required value of $min. '
          'Please provide a number greater than or equal to $min.',
      context: {
        'value': value,
        'min': min,
        'difference': min - value,
        'suggestion': 'Try using a value at least ${min - value} higher',
      },
    );
  }
}

class MaxValueValidator<T extends num> extends ConstraintValidator<T> {
  final num max;
  const MaxValueValidator(this.max);

  @override
  String get name => 'num_max_value';

  @override
  String get description => 'Must be less than or equal to $max';

  @override
  bool check(num value) => value <= max;

  @override
  ConstraintError onError(num value) {
    return buildError(
      message: 'Value $value exceeds the maximum allowed value of $max. '
          'Please provide a number less than or equal to $max.',
      context: {
        'value': value,
        'max': max,
        'excess': value - max,
        'suggestion': 'Try using a value at least ${value - max} lower',
      },
    );
  }
}

class RangeValidator<T extends num> extends ConstraintValidator<T> {
  final num min;
  final num max;
  const RangeValidator(this.min, this.max);

  @override
  String get name => 'num_range';

  @override
  String get description => 'Must be between $min and $max (inclusive)';

  @override
  bool check(num value) => value >= min && value <= max;

  @override
  ConstraintError onError(num value) {
    return buildError(
      message: 'Value $value is outside the required range of $min to $max. '
          'Please provide a number between $min and $max (inclusive).',
      context: {
        'value': value,
        'min': min,
        'max': max,
        'distance_from_min': value < min ? min - value : null,
        'distance_from_max': value > max ? value - max : null,
        'suggestion': value < min
            ? 'Try increasing the value by at least ${min - value}'
            : 'Try decreasing the value by at least ${value - max}',
      },
    );
  }
}
