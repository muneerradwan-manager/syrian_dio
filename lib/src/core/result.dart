import 'network_error.dart';

sealed class Result<T> {
  const Result();
  R fold<R>(R Function(NetworkError e) onError, R Function(T data) onOk);
  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;
}

class Ok<T> extends Result<T> {
  final T data;
  const Ok(this.data);

  @override
  R fold<R>(R Function(NetworkError e) onError, R Function(T data) onOk) => onOk(data);
}

class Err<T> extends Result<T> {
  final NetworkError error;
  const Err(this.error);

  @override
  R fold<R>(R Function(NetworkError e) onError, R Function(T data) onOk) => onError(error);
}
