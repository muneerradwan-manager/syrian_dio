import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syrian_dio/syrian_dio.dart';

void main() {
  group('Dio error mapping', () {
    test('offline device maps to noInternet with preserved details', () async {
      final adapter = _FakeHttpClientAdapter((options, _) async {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'SocketException: Network is unreachable (errno = 101)',
        );
      });

      final client = _buildClient(adapter: adapter, enableRetry: false);

      final result = await client.get<dynamic>('/ping', parser: (raw) => raw);
      final error = _expectErr(result);

      expect(error.type, NetworkErrorType.noInternet);
      expect(error.rawMessage, contains('Network is unreachable'));
      expect(error.host, 'api.example.com');
      expect(error.uri?.host, 'api.example.com');
    });

    test('invalid hostname maps to dnsFailure with host details', () async {
      final adapter = _FakeHttpClientAdapter((options, _) async {
        throw DioException.connectionError(
          requestOptions: options,
          reason: "SocketException: Failed host lookup: '${options.uri.host}'",
        );
      });

      final client = _buildClient(
        adapter: adapter,
        baseUrl: 'https://typo.invalid',
        enableRetry: false,
      );

      final result = await client.get<dynamic>('/health', parser: (raw) => raw);
      final error = _expectErr(result);

      expect(error.type, NetworkErrorType.dnsFailure);
      expect(error.host, 'typo.invalid');
      expect(error.message, contains('DNS lookup failed'));
      expect(error.rawMessage, contains('Failed host lookup'));
    });

    test('timeout maps to timeout', () async {
      final adapter = _FakeHttpClientAdapter((options, _) async {
        throw DioException.connectionTimeout(
          timeout: const Duration(seconds: 2),
          requestOptions: options,
        );
      });

      final client = _buildClient(adapter: adapter, enableRetry: false);

      final result = await client.get<dynamic>('/slow', parser: (raw) => raw);
      final error = _expectErr(result);

      expect(error.type, NetworkErrorType.timeout);
    });

    test('404 maps to notFound', () async {
      final adapter = _FakeHttpClientAdapter((_, _) async {
        return ResponseBody.fromString(
          '{"error":"not found"}',
          404,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>['application/json'],
          },
        );
      });

      final client = _buildClient(adapter: adapter, enableRetry: false);

      final result = await client.get<dynamic>(
        '/missing',
        parser: (raw) => raw,
      );
      final error = _expectErr(result);

      expect(error.type, NetworkErrorType.notFound);
      expect(error.statusCode, 404);
    });

    test('500 maps to server', () async {
      final adapter = _FakeHttpClientAdapter((_, _) async {
        return ResponseBody.fromString(
          '{"error":"server"}',
          500,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>['application/json'],
          },
        );
      });

      final client = _buildClient(adapter: adapter, enableRetry: false);

      final result = await client.get<dynamic>(
        '/explode',
        parser: (raw) => raw,
      );
      final error = _expectErr(result);

      expect(error.type, NetworkErrorType.server);
      expect(error.statusCode, 500);
    });
  });

  group('Retry behavior', () {
    test('does not retry deterministic DNS lookup failures', () async {
      final adapter = _FakeHttpClientAdapter((options, _) async {
        throw DioException.connectionError(
          requestOptions: options,
          reason: "SocketException: Failed host lookup: '${options.uri.host}'",
        );
      });

      final client = _buildClient(
        adapter: adapter,
        baseUrl: 'https://typo.invalid',
        enableRetry: true,
        maxRetries: 3,
      );

      final result = await client.get<dynamic>('/ping', parser: (raw) => raw);
      final error = _expectErr(result);

      expect(error.type, NetworkErrorType.dnsFailure);
      expect(adapter.fetchCount, 1);
    });
  });
}

NetworkError _expectErr<T>(Result<T> result) {
  expect(result, isA<Err<T>>());
  return (result as Err<T>).error;
}

DioNetworkClient _buildClient({
  required _FakeHttpClientAdapter adapter,
  required bool enableRetry,
  String baseUrl = 'https://api.example.com',
  int maxRetries = 3,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );
  dio.httpClientAdapter = adapter;

  return DioNetworkClient(
    config: DioConfig(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
    dio: dio,
    enableRetry: enableRetry,
    maxRetries: maxRetries,
    enableLogging: false,
  );
}

typedef _FetchHandler =
    Future<ResponseBody> Function(RequestOptions options, int attempt);

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._handler);

  final _FetchHandler _handler;
  int fetchCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    fetchCount += 1;
    return _handler(options, fetchCount);
  }

  @override
  void close({bool force = false}) {}
}
