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
  String toString() => toJson();
}

final class ConstraintError<C extends Constraint> with ErrorBase {
  @override
  final String key;

  final C constraint;

  @override
  final String message;

  ConstraintError({
    required this.key,
    required this.message,
    required this.constraint,
  });

  @override
  Map<String, Object?> toMap() {
    return {'key': key, 'message': message, 'constraint': constraint.toMap()};
  }

  @override
  String toString() => '$runtimeType: $key: $message';
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
      : ConstraintError(
          key: key,
          message: buildMessage(value),
          constraint: this,
        );
}
