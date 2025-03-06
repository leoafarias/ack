part of '../schema.dart';

final class ListSchema<V extends Object> extends Schema<List<V>>
    with SchemaFluentMethods<ListSchema<V>, List<V>> {
  final Schema<V> _itemSchema;
  const ListSchema(
    Schema<V> itemSchema, {
    super.constraints = const [],
    super.nullable,
    super.description,
    super.defaultValue,
  })  : _itemSchema = itemSchema,
        super(type: SchemaType.list);

  @override
  SchemaError? _validateAsType(List<V> value) {
    final error = super._validateAsType(value);

    if (error != null) return error;

    final constraintErrors = <int, SchemaError>{};

    for (var i = 0; i < value.length; i++) {
      final indexError = _itemSchema.validateSchema(value[i]);

      if (indexError == null) continue;

      constraintErrors[i] = indexError;
    }

    if (constraintErrors.isEmpty) return null;

    return ListSchemaError(errors: constraintErrors);
  }

  Schema<V> getItemSchema() => _itemSchema;

  @override
  List<V>? tryParse(Object value) {
    if (value is! List) return null;

    List<V>? parsedList = <V>[];
    for (final v in value) {
      final parsed = _itemSchema.tryParse(v);
      if (parsed == null) {
        parsedList = null;
        break;
      }
      parsedList!.add(parsed);
    }

    return parsedList;
  }

  @override
  ListSchema<V> copyWith({
    List<ConstraintValidator<List<V>>>? constraints,
    bool? nullable,
    String? description,
    List<V>? defaultValue,
  }) {
    return ListSchema(
      _itemSchema,
      constraints: constraints ?? _constraints,
      nullable: nullable ?? _nullable,
      description: description ?? _description,
      defaultValue: defaultValue ?? _defaultValue,
    );
  }

  @override
  ListSchema<V> call({
    bool? nullable,
    String? description,
    List<ConstraintValidator<List<V>>>? constraints,
    List<V>? defaultValue,
  }) {
    return copyWith(
      constraints: constraints,
      nullable: nullable,
      description: description,
      defaultValue: defaultValue,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {...super.toMap(), 'itemSchema': _itemSchema.toMap()};
  }
}
