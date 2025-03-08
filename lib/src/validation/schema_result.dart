import '../schemas/schema.dart';
import 'ack_exception.dart';
import 'schema_error.dart';

/// Represents either a successful outcome or a failure.
///
/// A [SchemaResult] encapsulates a successful value (an [Ok] instance)
/// or a failure (a [Fail] instance containing a list of [SchemaViolation]s).
class SchemaResult<T extends Object> {
  final Schema _schema;

  /// Creates a new [SchemaResult] instance.
  const SchemaResult(this._schema);

  /// Returns a successful result that wraps the given [value].
  static SchemaResult<T> ok<T extends Object>(T value, Schema schema) {
    return Ok(value, schema);
  }

  /// Returns a failure result that wraps the specified list of [errors].
  static SchemaResult<T> fail<T extends Object>(
    SchemaViolation error,
    Schema schema,
  ) {
    return Fail(error, schema);
  }

  static SchemaResult<T> unit<T extends Object>(Schema schema) {
    return Ok(Unit._(), schema);
  }

  /// Indicates whether this result is successful.
  ///
  /// Returns `true` if this instance is an [Ok].
  bool get isOk => this is Ok<T>;

  /// Indicates whether this result represents a failure.
  ///
  /// Returns `true` if this instance is a [Fail].
  bool get isFail => this is Fail<T>;

  /// Returns the list of errors associated with this result.
  ///
  /// If this result is successful, it returns an empty list.
  /// If this result is a failure, it returns the list of errors.
  SchemaViolation getViolation() {
    if (isOk) {
      throw ExceptionViolation(
        error: 'Cannot get violation from Ok',
        stackTrace: StackTrace.current,
        schema: _schema,
      );
    }

    return (this as Fail<T>).error;
  }

  /// Returns the contained value if this result is successful; otherwise, returns `null`.
  T? getOrNull() {
    return match(onOk: (value) => value, onFail: (_) => null);
  }

  /// Returns the contained value if this result is successful; otherwise, returns the result of [orElse].
  ///
  /// If this instance is an [Ok], it returns its contained value.
  /// Otherwise, it returns the value produced by invoking [orElse].
  T getOrElse(T Function() orElse) {
    return match(onOk: (value) => value, onFail: (_) => orElse());
  }

  /// Returns the contained value if this result is successful; otherwise, throws an [AckViolationException].
  ///
  /// If this instance is an [Ok], it returns its contained value.
  /// Otherwise, it throws an [AckViolationException] with the associated errors.
  T getOrThrow() {
    return match(
      onOk: (value) => value,
      onFail: (error) => throw AckViolationException(error),
    );
  }

  /// Executes the appropriate callback based on whether this result is successful or a failure.
  ///
  /// If this instance is an [Ok], it invokes [onOk] with the contained value.
  /// If this instance is a [Fail], it invokes [onFail] with the associated errors.
  ///
  /// Returns the result of the invoked callback.
  R match<R>({
    required R Function(T value) onOk,
    required R Function(SchemaViolation error) onFail,
  }) {
    final self = this;

    try {
      if (self is Ok<T>) {
        final value = self._value;

        if (value is Unit) {
          throw Exception(
            'Value should be type ${T.runtimeType}, but its null',
          );
        }

        return onOk(value as T);
      }
    } catch (e, stackTrace) {
      return onFail(ExceptionViolation(
        error: e,
        stackTrace: stackTrace,
        schema: _schema,
      ));
    }

    return onFail((self as Fail<T>).error);
  }

  /// Invokes [onFail] if this result represents a failure.
  ///
  /// If this instance is a [Fail], it calls [onFail] with its list of errors.
  /// Otherwise, it does nothing.
  void onFail(void Function(SchemaViolation error) onFail) {
    match(onOk: (_) {}, onFail: onFail);
  }

  /// Invokes [onOk] if this result is successful.
  ///
  /// If this instance is an [Ok], it calls [onOk] with its contained value.
  /// Otherwise, it does nothing.
  void onOk(void Function(T value) onOk) {
    match(onOk: onOk, onFail: (_) {});
  }
}

class Unit {
  const Unit._();
}

/// Represents a successful outcome that optionally wraps a value.
///
/// An [Ok] instance indicates that an operation succeeded and may contain a value.
/// If no meaningful value is provided, [getOrNull] returns `null`.
final class Ok<T extends Object> extends SchemaResult<T> {
  final Object _value;

  const Ok(this._value, super.schema);
}

/// Represents a failure outcome with associated errors.
///
/// A [Fail] instance indicates that an operation failed and encapsulates a list
/// of [SchemaViolation]s describing what went wrong.
class Fail<T extends Object> extends SchemaResult<T> {
  /// The list of errors associated with this failure.

  final SchemaViolation error;

  /// Creates a failure result with the specified [error].
  const Fail(this.error, super.schema);
}
