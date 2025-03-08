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

  Schema<V> getItemSchema() => _itemSchema;

  @override
  SchemaResult<List<V>> validateValue(
    Object? value,
    SchemaContext<List<V>> context,
  ) {
    final result = super.validateValue(value, context);

    if (result.isFail) return result;

    final listValue = result.getOrNull();

    if (_nullable && listValue == null) return context.unit();

    final itemsViolation = <int, SchemaViolation>{};

    for (var i = 0; i < listValue!.length; i++) {
      final itemResult = _itemSchema.validate(listValue[i], debugName: '$i');

      if (itemResult.isFail) {
        itemsViolation[i] = itemResult.getViolation();
      }
    }

    if (itemsViolation.isEmpty) return context.ok(listValue);

    return context.fail(
      ListSchemaViolation(violations: itemsViolation, context: context),
    );
  }

  @override
  List<V>? tryParse(Object? value) {
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
      constraints: constraints ?? _validators,
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
