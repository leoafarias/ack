import '../helpers.dart';
import 'schema_error.dart';

class AckViolationException implements Exception {
  final SchemaError violation;

  const AckViolationException(this.violation);

  @Deprecated('Use violation instead')
  SchemaError get error => violation;

  Map<String, dynamic> toMap() {
    return {'violation': violation.toMap()};
  }

  String toJson() => prettyJson(toMap());

  @override
  String toString() {
    return 'AckViolationException: ${toJson()}';
  }
}
