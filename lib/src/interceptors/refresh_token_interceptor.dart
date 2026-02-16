import 'dart:async';
import 'package:dio/dio.dart';
import '../token/token_store.dart';
import '../token/refresh_types.dart';

/// Handles 401 responses by refreshing tokens once and retrying the request.
class RefreshTokenInterceptor extends Interceptor {
  /// Dio instance used for the retried request after refresh succeeds.
  final Dio dio;

  /// Token persistence abstraction.
  final TokenStore tokenStore;

  /// User-defined refresh call.
  final RefreshCall refreshCall;

  /// Called when refresh flow fails and request cannot be recovered.
  final void Function()? onRefreshFailed;

  /// Synchronizes concurrent 401 requests into a single refresh operation.
  Completer<void>? _refreshCompleter;

  /// Path fragment used to identify refresh endpoint requests.
  final String refreshPathContains;

  /// Creates a refresh token interceptor.
  RefreshTokenInterceptor({
    required this.dio,
    required this.tokenStore,
    required this.refreshCall,
    this.onRefreshFailed,
    this.refreshPathContains = '/auth/refresh',
  });

  bool _is401(DioException err) => err.response?.statusCode == 401;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_is401(err)) return handler.next(err);

    // إذا الطلب هو refresh نفسه، لا تعمل refresh مرة ثانية
    if (err.requestOptions.path.contains(refreshPathContains)) {
      onRefreshFailed?.call();
      return handler.next(err);
    }

    try {
      await _refreshTokenOnce();

      final newAccess = await tokenStore.getAccessToken();
      if (newAccess == null || newAccess.isEmpty) {
        onRefreshFailed?.call();
        return handler.next(err);
      }

      final retried = await _retry(err.requestOptions, newAccess);
      return handler.resolve(retried);
    } catch (_) {
      onRefreshFailed?.call();
      return handler.next(err);
    }
  }

  Future<void> _refreshTokenOnce() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<void>();

    try {
      final refreshToken = await tokenStore.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw StateError('No refresh token');
      }

      final result = await refreshCall(refreshToken: refreshToken);

      await tokenStore.saveAccessToken(result.accessToken);
      if (result.refreshToken != null && result.refreshToken!.isNotEmpty) {
        await tokenStore.saveRefreshToken(result.refreshToken!);
      }

      _refreshCompleter!.complete();
    } catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions, String accessToken) {
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    headers['Authorization'] = 'Bearer $accessToken';

    final opts = Options(
      method: requestOptions.method,
      headers: headers,
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
      followRedirects: requestOptions.followRedirects,
      receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
      extra: Map<String, dynamic>.from(requestOptions.extra),
      validateStatus: requestOptions.validateStatus,
      sendTimeout: requestOptions.sendTimeout,
      receiveTimeout: requestOptions.receiveTimeout,
    );

    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: opts,
      cancelToken: requestOptions.cancelToken,
      onSendProgress: requestOptions.onSendProgress,
      onReceiveProgress: requestOptions.onReceiveProgress,
    );
  }
}
