import 'network_error.dart';

/// Represents either successful data ([Ok]) or a [NetworkError] ([Err]).
sealed class Result<T> {
  const Result();

  /// Pattern-matching helper for success/error branches.
  R fold<R>(R Function(NetworkError e) onError, R Function(T data) onOk);

  /// Returns `true` when this value is [Ok].
  bool get isOk => this is Ok<T>;

  /// Returns `true` when this value is [Err].
  bool get isErr => this is Err<T>;
}

/// Successful [Result] container.
class Ok<T> extends Result<T> {
  /// Parsed response value.
  final T data;

  /// Creates an [Ok] result.
  const Ok(this.data);

  @override
  R fold<R>(R Function(NetworkError e) onError, R Function(T data) onOk) => onOk(data);
}

/// Failed [Result] container.
class Err<T> extends Result<T> {
  /// Error details.
  final NetworkError error;

  /// Creates an [Err] result.
  const Err(this.error);

  @override
  R fold<R>(R Function(NetworkError e) onError, R Function(T data) onOk) => onError(error);
}
