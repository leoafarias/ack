import '../helpers.dart';
import 'schema_error.dart';

class AckException implements Exception {
  final List<SchemaError> errors;

  const AckException(this.errors);

  Map<String, dynamic> toMap() {
    return {'errors': errors.map((e) => e.toMap()).toList()};
  }

  String toJson() => prettyJson(toMap());

  @override
  String toString() {
    return 'AckException: ${toJson()}';
  }
}
