import 'package:meta/meta.dart';

import '../helpers.dart';
import '../validation/schema_error.dart';

abstract class Constraint<T extends Object> {
  final String key;

  final String description;

  const Constraint({required this.key, required this.description});

  Map<String, Object?> toMap() {
    return {'key': key, 'description': description};
  }

  String toJson() => prettyJson(toMap());

  @override
  String toString() => '$runtimeType: $key: $description';
}

final class ConstraintError with ErrorBase {
  final Constraint constraint;

  @override
  final String message;

  ConstraintError({required this.message, required this.constraint});

  Type get type => constraint.runtimeType;

  @override
  Map<String, Object?> toMap() {
    return {'message': message, 'constraint': constraint.toMap()};
  }

  @override
  String toString() => '$runtimeType: $key: $message';

  @override
  String get key => constraint.key;
}

mixin OpenApiSpec<T extends Object> on Constraint<T> {
  Map<String, Object?> toOpenApiSpec();
}

mixin Validator<T extends Object> on Constraint<T> {
  @protected
  String buildMessage(T value);

  @protected
  bool isValid(T value);

  ConstraintError? validate(T value) => isValid(value)
      ? null
      : ConstraintError(message: buildMessage(value), constraint: this);
}

mixin WithConstraintError<T> on Constraint {
  @protected
  String buildMessage(T value);

  ConstraintError buildError(T value) {
    return ConstraintError(message: buildMessage(value), constraint: this);
  }
}
