part of '../schema.dart';

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
  final int min;
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
  final int max;

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
