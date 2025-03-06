import 'package:ack/src/helpers/template.dart';
import 'package:meta/meta.dart';

import '../context.dart';
import '../helpers.dart';
import 'schema_error.dart';

abstract class ConstraintValidator<T extends Object> {
  final String name;

  final String description;

  const ConstraintValidator({required this.name, required this.description});

  String get errorTemplate;

  bool isValid(T value);

  ConstraintError? validate(T value) => isValid(value) ? null : onError(value);

  ConstraintError onError(T value);

  Map<String, Object?> toMap() {
    return {'name': name, 'description': description};
  }

  String toJson() => prettyJson(toMap());

  @protected
  ConstraintError buildError({required Map<String, Object?> extra}) {
    final context = ViolationContext.getWithExtras(extra);
    final template = Template(errorTemplate, data: context.toMap());

    return ConstraintError(
      key: name,
      message: template.render(),
      context: context,
    );
  }

  @override
  String toString() => toJson();
}

mixin OpenAPiSpecOutput<T extends Object> on ConstraintValidator<T> {
  Map<String, Object?> toSchema();
}
