import 'package:meta/meta.dart';

import '../helpers.dart';
import 'schema_error.dart';

abstract class ConstraintValidator<T extends Object> {
  final String name;

  final String description;

  const ConstraintValidator({required this.name, required this.description});

  @protected
  ConstraintError buildError(T value);

  @protected
  bool isValid(T value);

  ConstraintError? validate(T value) =>
      isValid(value) ? null : buildError(value);

  Map<String, Object?> toMap() {
    return {'name': name, 'description': description};
  }

  String toJson() => prettyJson(toMap());

  @override
  String toString() => toJson();
}

mixin OpenAPiSpecOutput<T extends Object> on ConstraintValidator<T> {
  Map<String, Object?> topOpenApiSchema();
}
