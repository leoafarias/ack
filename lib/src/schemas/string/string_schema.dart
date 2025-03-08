part of '../schema.dart';

final class StringSchema extends ScalarSchema<StringSchema, String> {
  @override
  final builder = StringSchema.new;

  const StringSchema({
    super.nullable,
    super.validators,
    super.strict,
    super.description,
    super.defaultValue,
  }) : super(type: SchemaType.string);
}
