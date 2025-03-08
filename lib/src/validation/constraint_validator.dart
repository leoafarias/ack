import 'package:meta/meta.dart';

import '../helpers.dart';
import 'schema_error.dart';

abstract class ConstraintValidator<T extends Object> {
  final String name;

  final String description;

  const ConstraintValidator({required this.name, required this.description});

  String get errorMessage;

  @protected
  ConstraintViolation buildError(T value, {Map<String, Object?>? extra}) {
    return ConstraintViolation(
      constraintName: name,
      message: errorMessage,
      variables: extra ?? {},
    );
  }

  @protected
  bool isValid(T value);

  ConstraintViolation? validate(T value) =>
      isValid(value) ? null : buildError(value);

  Map<String, Object?> toMap() {
    return {'name': name, 'description': description};
  }

  String toJson() => prettyJson(toMap());

  @override
  String toString() => toJson();
}

mixin OpenAPiSpecOutput<T extends Object> on ConstraintValidator<T> {
  Map<String, Object?> toSchema();
}
