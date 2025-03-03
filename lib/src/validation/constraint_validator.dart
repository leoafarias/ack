import 'package:meta/meta.dart';

import '../helpers.dart';
import 'schema_error.dart';

abstract class ConstraintValidator<T extends Object> {
  final String name;

  final String description;
  const ConstraintValidator({required this.name, required this.description});

  bool isValid(T value);

  ConstraintError? validate(T value) => isValid(value) ? null : onError(value);

  ConstraintError onError(T value);

  Map<String, Object?> toMap() {
    return {'name': name, 'description': description};
  }

  String toJson() => prettyJson(toMap());

  @protected
  ConstraintError buildError({
    required String template,
    required Map<String, Object?> context,
  }) {
    return ConstraintError(name: name, message: template, context: context);
  }

  @override
  String toString() => toJson();
}

mixin OpenAPiSpecOutput<T extends Object> on ConstraintValidator<T> {
  Map<String, Object?> toSchema();
}
