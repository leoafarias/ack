import 'package:ack/src/helpers/template.dart';
import 'package:ack/src/schemas/schema.dart';
import 'package:meta/meta.dart';

import '../context.dart';
import '../helpers.dart';
import 'schema_error.dart';

abstract class ConstraintValidator<T extends Object> {
  final String name;

  final String description;

  const ConstraintValidator({required this.name, required this.description});

  ViolationContext _getWithExtras(T value, Map<String, Object?> extra) {
    ViolationContext? context =
        maybeGetCurrentViolationContext<Schema<Object>>();

    return context == null
        ? ViolationContext(value: value, extra: extra)
        : context.mergeExtras(extra);
  }

  String get errorTemplate;

  @protected
  ConstraintViolation buildError(T value, {Map<String, Object?>? extra}) {
    final context = _getWithExtras(value, extra ?? {});
    final template = Template(errorTemplate, data: context.toMap());

    return ConstraintViolation(
      key: name,
      message: template.render(),
      context: context,
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
