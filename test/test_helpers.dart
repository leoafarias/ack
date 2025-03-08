import 'package:ack/ack.dart';
import 'package:ack/src/context.dart';
import 'package:test/test.dart';

class IsSchemaError extends Matcher {
  final String key;

  IsSchemaError(this.key);

  @override
  bool matches(item, Map matchState) {
    return item is SchemaViolation && item.key == key;
  }

  @override
  Description describe(Description description) {
    return description.add(
      'a SchemaError containing error key "$key"',
    );
  }

  @override
  Description describeMismatch(
    item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is! SchemaViolation) {
      return mismatchDescription.add('was not a SchemaError');
    }

    return mismatchDescription.add(
      'had error key "$item" instead of "$key"',
    );
  }
}

class IsConstraintError extends Matcher {
  final String key;

  IsConstraintError(this.key);

  @override
  bool matches(item, Map matchState) {
    return item is ConstraintViolation && item.key == key;
  }

  @override
  Description describe(Description description) {
    return description.add(
      'a ConstraintError containing error key "$key"',
    );
  }

  @override
  Description describeMismatch(
    item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is! ConstraintViolation) {
      return mismatchDescription.add('was not a ConstraintError');
    }
    return mismatchDescription.add(
      'Constrained key is "$item" instead of "$key"',
    );
  }
}

class HasSchemaErrors extends Matcher {
  final List<String> types;
  final int expectedCount;

  /// [types] is a list of allowed SchemaError types.
  /// [expectedCount] is an optional parameter; if provided, the Fail result must contain exactly that many errors.
  HasSchemaErrors(this.types, this.expectedCount);

  @override
  bool matches(item, Map matchState) {
    final isFail = item is Fail;
    final isErrors = item is SchemaViolation;
    if (!isFail && !isErrors) {
      matchState['reason'] = 'was not a Fail result or a SchemaError';
      return false;
    }

    final schemaError = item is Fail ? item.error : item as SchemaViolation;

    final errors = getErrors(schemaError, []);

    if (errors.length != expectedCount) {
      matchState['reason'] =
          'expected $expectedCount SchemaErrors with types $types, but found ${errors.length} errors with types ${errors.map((e) => e.key).toList()}';
      return false;
    }

    if (errors.isEmpty) {
      matchState['reason'] = 'Fail result did not contain any SchemaErrors';
      return false;
    }

    for (final error in errors) {
      if (!types.contains(error.key)) {
        matchState['reason'] =
            'expected $expectedCount SchemaErrors with types $types, but found ${errors.length} errors with types ${errors.map((e) => e.key).toList()}';
        return false;
      }
    }

    return true;
  }

  @override
  Description describe(Description description) {
    return description.add(
        'a Fail result containing $expectedCount SchemaErrors with types $types');
  }

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    if (matchState.containsKey('reason')) {
      mismatchDescription.add(matchState['reason']);
    } else {
      mismatchDescription.add('was $item');
    }
    return mismatchDescription;
  }
}

List<SchemaViolation> getErrors(
    SchemaViolation error, List<SchemaViolation> aggregatedErrors) {
  final extractedErrors = switch (error) {
    SchemaConstraintViolation constraintsError => [constraintsError],
    ObjectSchemaViolation propertiesError =>
      propertiesError.errors.values.toList(),
    ListSchemaViolation itemsError => itemsError.errors.values.toList(),
    DiscriminatedSchemaViolation discriminatedError => [
        discriminatedError.error
      ],
    UnknownSchemaViolation() => [error],
  };

  return [...aggregatedErrors, ...extractedErrors];
}

class HasConstraintErrors extends Matcher {
  final List<String> names;
  final int expectedCount;

  HasConstraintErrors(this.names, this.expectedCount);

  @override
  bool matches(item, Map matchState) {
    if (item is! Fail) {
      matchState['reason'] = 'was not a Fail result';
      return false;
    }

    final error = item.error;

    if (error is! SchemaConstraintViolation) {
      matchState['reason'] = 'was not a SchemaConstraintsError';
      return false;
    }

    final errors = error.constraints;

    if (errors.length != expectedCount) {
      matchState['reason'] =
          'expected $expectedCount ConstraintErrors with names $names, but found ${errors.length} errors with names ${errors.map((e) => e.key).toList()}';
      return false;
    }

    for (final error in errors) {
      if (!names.contains(error.key)) {
        matchState['reason'] =
            'expected $expectedCount ConstraintErrors with names $names, but found ${errors.length} errors with names ${errors.map((e) => e.key).toList()}';
        return false;
      }
    }

    return true;
  }

  @override
  Description describe(Description description) {
    return description.add(
        'a Fail result containing $expectedCount ConstraintErrors with names $names');
  }

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    if (matchState.containsKey('reason')) {
      mismatchDescription.add(matchState['reason']);
    } else {
      mismatchDescription.add('was $item');
    }
    return mismatchDescription;
  }
}

Matcher _hasSchemaErrors(List<String> types, {required int count}) {
  assert(
    count == types.length,
    'count must be equal to the number of types in the list',
  );
  return HasSchemaErrors(types, count);
}

class IsOkMatcher<T extends Object> extends Matcher {
  const IsOkMatcher();

  @override
  bool matches(item, Map matchState) {
    // Check if the item is of type Ok<T, E>.
    if (item is! Ok<T>) {
      // Save extra info in matchState.
      matchState['actualType'] = item.runtimeType;
      matchState['expectedType'] = 'Ok<$T>';
      return false;
    }
    return true;
  }

  @override
  Description describe(Description description) =>
      description.add('an Ok result of type Ok<$T>');

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    // Use the stored values to generate a more helpful message.
    if (matchState.containsKey('actualType') &&
        matchState.containsKey('expectedType')) {
      mismatchDescription.add('has type ${matchState['actualType']}, '
          'but expected ${matchState['expectedType']}');
    } else {
      mismatchDescription.add('was $item');
    }
    return mismatchDescription;
  }
}

Matcher isSchemaError(String type) => IsSchemaError(type);
Matcher isConstraintError(String name) => IsConstraintError(name);

Matcher hasOneSchemaError(String type) => _hasSchemaErrors([type], count: 1);

Matcher hasSchemaErrors(List<String> types, {required int count}) =>
    _hasSchemaErrors(types, count: count);

Matcher hasOneConstraintError(String name) => HasConstraintErrors([name], 1);

Matcher hasConstraintErrors(List<String> names, {required int count}) =>
    HasConstraintErrors(names, count);

extension FailExt<T extends Object> on Fail<T> {
  List<ConstraintViolation> get constraintErrors {
    if (error is! SchemaConstraintViolation) {
      throw ArgumentError('error is not a SchemaError');
    }
    return (error as SchemaConstraintViolation)
        .constraints
        .whereType<ConstraintViolation>()
        .toList();
  }
}

class MockViolationContext extends ViolationContext {
  MockViolationContext({Map<String, Object?>? extra, Schema? schema})
      : super(name: 'mock_context', schema: schema, extra: extra);
}
