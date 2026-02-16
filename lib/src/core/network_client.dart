import 'http_method.dart';
import 'network_request.dart';
import 'result.dart';

abstract class NetworkClient {
  Future<Result<T>> send<T>({
    required NetworkRequest request,
    required T Function(dynamic raw) parser,
  });

  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic raw) parser,
  }) {
    return send<T>(
      request: NetworkRequest(
        method: HttpMethod.get,
        path: path,
        query: query,
        headers: headers,
      ),
      parser: parser,
    );
  }

  Future<Result<T>> post<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic raw) parser,
  }) {
    return send<T>(
      request: NetworkRequest(
        method: HttpMethod.post,
        path: path,
        body: body,
        query: query,
        headers: headers,
      ),
      parser: parser,
    );
  }

  Future<Result<T>> put<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic raw) parser,
  }) {
    return send<T>(
      request: NetworkRequest(
        method: HttpMethod.put,
        path: path,
        body: body,
        query: query,
        headers: headers,
      ),
      parser: parser,
    );
  }

  Future<Result<T>> patch<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic raw) parser,
  }) {
    return send<T>(
      request: NetworkRequest(
        method: HttpMethod.patch,
        path: path,
        body: body,
        query: query,
        headers: headers,
      ),
      parser: parser,
    );
  }

  Future<Result<T>> delete<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    required T Function(dynamic raw) parser,
  }) {
    return send<T>(
      request: NetworkRequest(
        method: HttpMethod.delete,
        path: path,
        body: body,
        query: query,
        headers: headers,
      ),
      parser: parser,
    );
  }
}
