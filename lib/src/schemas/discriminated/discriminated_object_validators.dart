part of '../schema.dart';

ConstraintError _missingDiscriminatorKeyInSchema(
  String discriminatorKey,
  String discriminatorValue,
) {
  return ConstraintError(
    name: 'missing_discriminator_key_in_schema',
    message:
        'Missing discriminator key: $discriminatorKey in schema: $discriminatorValue',
    context: {
      'discriminator_key': discriminatorKey,
      'discriminator_value': discriminatorValue,
    },
  );
}

ConstraintError _noSchemaForDiscriminatorValue(
  String discriminatorKey,
  String discriminatorValue,
) {
  return ConstraintError(
    name: 'no_schema_for_discriminator_value',
    message:
        'No schema found for discriminator value: $discriminatorValue for discriminator key: $discriminatorKey',
    context: {
      'discriminator_key': discriminatorKey,
      'discriminator_value': discriminatorValue,
    },
  );
}

ConstraintError _keyMustBeRequiredInSchema(
  String discriminatorKey,
  ObjectSchema schema,
) {
  return ConstraintError(
    name: 'key_must_be_required_in_schema',
    message: 'Key is required in schema: $discriminatorKey for schema: $schema',
    context: {'discriminator_key': discriminatorKey, 'schema': schema},
  );
}

ConstraintError _missingDiscriminatorKeyInValue(
  String discriminatorKey,
  MapValue value,
) {
  return ConstraintError(
    name: 'missing_discriminator_key',
    message: 'Missing discriminator key: $discriminatorKey in value: $value',
    context: {'discriminator_key': discriminatorKey, 'value': value},
  );
}
