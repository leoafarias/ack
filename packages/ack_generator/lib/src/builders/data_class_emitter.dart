import '../json/helper_names.dart';
import '../models/schema_model_graph.dart';

/// Shared copy/equality/hash/string emission for class-first and schema-first
/// data classes.
final class AckDataClassEmitter {
  const AckDataClassEmitter({this.ackPrefix});

  static const _copyWithUnset = '_ackCopyWithUnset';

  final String? ackPrefix;

  /// Private mixin applied by a hand-written `@AckModel` class.
  String mixin({
    required String className,
    required String facadeName,
    required List<AckFieldNode> fields,
    required List<AckConstructorParameter> constructorParameters,
    required bool includeValueMembers,
    String? captureFieldName,
  }) {
    final stored = [
      ...fields,
      if (captureFieldName != null)
        AckFieldNode(
          dartName: captureFieldName,
          jsonKey: captureFieldName,
          presence: AckSchemaFieldPresence.required,
          nullable: false,
          runtimeRef: const AckMapTypeRef(
            AckNullableTypeRef(AckScalarTypeRef('Object')),
          ),
        ),
    ];
    final members = [
      if (includeValueMembers) ...[
        copyWithMethod(
          className: className,
          constructorParameters: constructorParameters,
          castSelf: true,
        ),
        equalityMembers(className: className, fields: stored, castSelf: true),
        toStringMethod(className: className, fields: stored, castSelf: true),
      ],
      jsonMembers(className: className, facadeName: facadeName),
    ];
    final needsCopyWithSentinel =
        includeValueMembers && constructorParameters.any(_usesCopyWithSentinel);
    final sentinelType = ackCopyWithUnsetTypeName(className);

    return '''
${needsCopyWithSentinel ? 'final class $sentinelType {\n  const $sentinelType();\n}\n\n' : ''}
mixin ${'_\$${className}Ack'} {
  ${needsCopyWithSentinel ? 'static const $sentinelType $_copyWithUnset = $sentinelType();\n\n  ' : ''}${members.join('\n\n  ')}
}''';
  }

  String copyWithMethod({
    required String className,
    required List<AckConstructorParameter> constructorParameters,
    bool castSelf = false,
  }) {
    final receiver = castSelf ? 'self' : 'this';
    final parameters = [
      for (final parameter in constructorParameters)
        if (_usesCopyWithSentinel(parameter))
          'Object? ${parameter.name} = $_copyWithUnset'
        else
          '${_copyWithType(parameter)} ${parameter.name}',
    ];
    final arguments = [
      for (final parameter in constructorParameters)
        _copyWithArgument(parameter, receiver),
    ];
    final parameterList = parameters.isEmpty
        ? ''
        : '{${parameters.join(', ')}}';
    if (castSelf) {
      return '''
$className copyWith($parameterList) {
  final self = this as $className;
  return $className(${arguments.join(', ')});
}''';
    }
    return '''
$className copyWith($parameterList) => $className(${arguments.join(', ')});''';
  }

  String equalityMembers({
    required String className,
    required List<AckFieldNode> fields,
    bool castSelf = false,
  }) {
    final hashes = [
      'runtimeType',
      for (final field in fields)
        _hash('${castSelf ? 'self' : 'this'}.${field.dartName}'),
    ];
    if (castSelf) {
      final fieldEquals = [
        for (final field in fields)
          _equals('self.${field.dartName}', 'other.${field.dartName}'),
      ];
      final equality = fieldEquals.isEmpty ? 'true' : fieldEquals.join(' && ');
      return '''
@override
bool operator ==(Object other) {
  if (identical(this, other)) return true;
  if (other is! $className || runtimeType != other.runtimeType) {
    return false;
  }
  final self = this as $className;
  return $equality;
}

@override
int get hashCode {
  final self = this as $className;
  return Object.hashAll([${hashes.join(', ')}]);
}''';
    }
    final comparisons = [
      'other is $className',
      'runtimeType == other.runtimeType',
      for (final field in fields)
        _equals('this.${field.dartName}', 'other.${field.dartName}'),
    ];
    return '''
@override
bool operator ==(Object other) =>
    identical(this, other) || (${comparisons.join(' && ')});

@override
int get hashCode => Object.hashAll([${hashes.join(', ')}]);''';
  }

  String toStringMethod({
    required String className,
    required List<AckFieldNode> fields,
    bool castSelf = false,
  }) {
    if (castSelf) {
      final parts = [
        for (final field in fields)
          '${field.dartName}: \${self.${field.dartName}}',
      ];
      return '''
@override
String toString() {
  final self = this as $className;
  return '$className(${parts.join(', ')})';
}''';
    }
    final parts = [
      for (final field in fields) '${field.dartName}: \$${field.dartName}',
    ];
    return '''
@override
String toString() => '$className(${parts.join(', ')})';''';
  }

  String jsonMembers({required String className, required String facadeName}) {
    return '''
Map<String, dynamic> toJson() =>
    Map<String, dynamic>.from($facadeName.encode(this as $className));

${_ack('SchemaResult')}<Map<String, Object?>> safeToJson() =>
    $facadeName.safeEncode(this as $className);''';
  }

  String _copyWithType(AckConstructorParameter parameter) =>
      '${_type(parameter.typeRef)}?';

  String _copyWithArgument(AckConstructorParameter parameter, String receiver) {
    final replacement = _usesCopyWithSentinel(parameter)
        ? 'identical(${parameter.name}, $_copyWithUnset) '
              '? $receiver.${parameter.fieldName} '
              ': ${parameter.name} as ${_type(parameter.typeRef)}'
        : '${parameter.name} ?? $receiver.${parameter.fieldName}';
    return parameter.kind == AckConstructorParameterKind.named
        ? '${parameter.name}: $replacement'
        : replacement;
  }

  bool _usesCopyWithSentinel(AckConstructorParameter parameter) =>
      parameter.typeRef is AckNullableTypeRef;

  String _equals(String left, String right) =>
      '${_ack('deepEquals')}($left, $right)';

  String _hash(String expression) => '${_ack('deepHashCode')}($expression)';

  String _type(AckInferRef type) => switch (type) {
    AckNullableTypeRef(:final inner) => '${_type(inner)}?',
    AckScalarTypeRef(:final dartType) => dartType,
    AckExternalTypeRef(:final visibleName, :final typeArguments) =>
      typeArguments.isEmpty
          ? visibleName
          : '$visibleName<${typeArguments.map(_type).join(', ')}>',
    AckModelTypeRef(:final visibleName) => visibleName,
    AckListTypeRef(:final elementType) => 'List<${_type(elementType)}>',
    AckSetTypeRef(:final elementType) => 'Set<${_type(elementType)}>',
    AckMapTypeRef(:final valueType) => 'Map<String, ${_type(valueType)}>',
  };

  String _ack(String symbol) {
    final prefix = ackPrefix;
    return prefix == null || prefix.isEmpty ? symbol : '$prefix.$symbol';
  }
}
