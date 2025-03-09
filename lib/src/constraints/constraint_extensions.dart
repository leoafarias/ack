import 'package:ack/src/constraints/constraint.dart';

import '../schemas/schema.dart';
import 'validators.dart';

/// Provides validation methods for [StringSchema].
extension StringSchemaValidatorExt on StringSchema {
  StringSchema _add(Validator<String> validator) =>
      withConstraints([validator]);

  /// {@macro email_validator}
  StringSchema isEmail() => _add(StringEmailValidator());

  /// {@macro hex_color_validator}
  StringSchema isHexColor() => _add(StringHexColorValidator());

  /// {@macro is_empty_validator}
  StringSchema isEmpty() => _add(const StringEmptyValidator());

  /// {@macro min_length_validator}
  StringSchema minLength(int min) => _add(StringMinLengthValidator(min));

  /// {@macro max_length_validator}
  StringSchema maxLength(int max) => _add(StringMaxLengthValidator(max));

  /// {@macro not_one_of_validator}
  StringSchema notOneOf(List<String> values) =>
      _add(StringNotOneOfValidator(values));

  /// {@macro is_json_validator}
  StringSchema isJson() => _add(const StringJsonValidator());

  /// {@macro enum_validator}
  StringSchema isEnum(List<String> values) => _add(StringEnumValidator(values));

  /// {@macro not_empty_validator}
  StringSchema isNotEmpty() => _add(const StringNotEmptyValidator());

  /// {@macro date_time_validator}
  StringSchema isDateTime() => _add(const StringDateTimeValidator());

  /// {@macro date_validator}
  StringSchema isDate() => _add(const StringDateValidator());
}

extension NumSchemaValidatorExt<T extends num> on NumSchema<T> {
  NumSchema<T> _add(Validator<T> validator) => withConstraints([validator]);

  /// {@macro min_num_validator}
  NumSchema<T> min(T min) => _add(NumberMinValidator(min));

  /// {@macro max_num_validator}
  NumSchema<T> max(T max) => _add(NumberMaxValidator(max));

  /// {@macro range_num_validator}
  NumSchema<T> range(T min, T max) => _add(NumberRangeValidator(min, max));

  /// {@macro multiple_of_num_validator}
  NumSchema<T> multipleOf(T multiple) =>
      _add(NumberMultipleOfValidator(multiple));
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
    return withConstraints([ObjectMinPropertiesValidator(min: min)]);
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
    return withConstraints([ObjectMaxPropertiesValidator(max: max)]);
  }
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
      withConstraints([ListMinItemsValidator(min)]);

  /// {@macro max_items_list_validator}
  ///
  /// Example:
  /// ```dart
  /// final schema = Ack.list(Ack.string).maxItems(3);
  /// ```
  ListSchema<T> maxItems(int max) =>
      withConstraints([ListMaxItemsValidator(max)]);
}
