# Full Integration Example

This guide shows how to use `syrian_dio` in a real app with:
- `get_it`
- `flutter_bloc` (`Cubit`)
- `dartz` (`Either`)
- `shared_preferences`
- `flutter_secure_storage`
- `internet_connection_checker`

It matches this folder direction:

```text
lib/
  core/
    di/
      get_it.dart
    network/
      dio.dart
      network_info.dart
      token_store.dart
      interceptors/
        app_headers_interceptor.dart
  feature/
    auth/
      data/
        models/
          auth_user_model.dart
        repositories/
          auth_failure.dart
          auth_repository.dart
          auth_repository_impl.dart
      presentation/
        cubits/
          auth_cubit.dart
          auth_state.dart
        pages/
          login_page.dart
        widgets/
          login_form.dart
  main.dart
```

## 1) App dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  syrian_dio: ^0.0.4
  dio: ^5.9.1
  get_it: ^8.0.3
  flutter_bloc: ^8.1.6
  dartz: ^0.10.1
  shared_preferences: ^2.3.2
  flutter_secure_storage: ^9.2.2
  internet_connection_checker: ^3.0.1
```

## 2) Core network layer

### `lib/core/network/network_info.dart`

```dart
import 'package:internet_connection_checker/internet_connection_checker.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker _checker;

  const NetworkInfoImpl(this._checker);

  @override
  Future<bool> get isConnected => _checker.hasConnection;
}
```

### `lib/core/network/token_store.dart`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:syrian_dio/syrian_dio.dart';

class SecureTokenStore implements TokenStore {
  static const String _accessKey = 'auth.access_token';
  static const String _refreshKey = 'auth.refresh_token';

  final FlutterSecureStorage _storage;

  const SecureTokenStore(this._storage);

  @override
  Future<String?> getAccessToken() => _storage.read(key: _accessKey);

  @override
  Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  @override
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessKey, value: token);

  @override
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshKey, value: token);

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
```

### `lib/core/network/interceptors/app_headers_interceptor.dart`

```dart
import 'package:dio/dio.dart';

class AppHeadersInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    options.headers['x-app-platform'] = 'flutter';
    options.headers['x-app-version'] = '1.0.0';
    handler.next(options);
  }
}
```

### `lib/core/network/dio.dart`

```dart
import 'package:dio/dio.dart';
import 'package:syrian_dio/syrian_dio.dart';

import 'interceptors/app_headers_interceptor.dart';

DioNetworkClient buildAppDioClient({
  required String baseUrl,
  required TokenStore tokenStore,
  void Function()? onUnauthorized,
}) {
  final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));

  return DioNetworkClient(
    config: DioConfig(
      baseUrl: baseUrl,
      tokenProvider: tokenStore.getAccessToken,
      onUnauthorized: onUnauthorized,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
    enableLogging: true,
    logBody: false,
    enableRetry: true,
    maxRetries: 2,
    enableRefreshToken: true,
    tokenStore: tokenStore,
    refreshCall: ({required refreshToken}) async {
      final response = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: <String, dynamic>{'refresh_token': refreshToken},
      );
      final json = response.data ?? <String, dynamic>{};

      return RefreshResult(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String?,
      );
    },
    extraInterceptors: <Interceptor>[
      AppHeadersInterceptor(),
    ],
  );
}
```

## 3) Dependency Injection with GetIt

### `lib/core/di/get_it.dart`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syrian_dio/syrian_dio.dart';

import '../../feature/auth/data/repositories/auth_repository.dart';
import '../../feature/auth/data/repositories/auth_repository_impl.dart';
import '../../feature/auth/presentation/cubits/auth_cubit.dart';
import '../network/dio.dart';
import '../network/network_info.dart';
import '../network/token_store.dart';

final GetIt sl = GetIt.instance;

Future<void> setupDependencies() async {
  const apiBaseUrl = 'https://api.example.com';

  final prefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();

  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<FlutterSecureStorage>(() => secureStorage);
  sl.registerLazySingleton<InternetConnectionChecker>(
    () => InternetConnectionChecker.instance,
  );

  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<TokenStore>(() => SecureTokenStore(sl()));

  sl.registerLazySingleton<DioNetworkClient>(
    () => buildAppDioClient(
      baseUrl: apiBaseUrl,
      tokenStore: sl(),
      onUnauthorized: () async {
        await sl<TokenStore>().clear();
        await sl<SharedPreferences>().remove('auth.cached_user');
      },
    ),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      client: sl(),
      networkInfo: sl(),
      prefs: sl(),
      tokenStore: sl(),
    ),
  );

  sl.registerFactory<AuthCubit>(() => AuthCubit(sl()));
}
```

## 4) Auth data layer (Dartz + Repository)

### `lib/feature/auth/data/models/auth_user_model.dart`

```dart
class AuthUserModel {
  final String id;
  final String email;
  final String name;

  const AuthUserModel({
    required this.id,
    required this.email,
    required this.name,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'].toString(),
      email: json['email'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'name': name,
    };
  }
}
```

### `lib/feature/auth/data/repositories/auth_failure.dart`

```dart
import 'package:syrian_dio/syrian_dio.dart';

class AuthFailure {
  final String message;
  final NetworkErrorType? type;
  final String? technicalDetails;

  const AuthFailure({
    required this.message,
    this.type,
    this.technicalDetails,
  });
}
```

### `lib/feature/auth/data/repositories/auth_repository.dart`

```dart
import 'package:dartz/dartz.dart';

import '../models/auth_user_model.dart';
import 'auth_failure.dart';

abstract class AuthRepository {
  Future<Either<AuthFailure, AuthUserModel>> login({
    required String email,
    required String password,
  });

  Future<Either<AuthFailure, AuthUserModel?>> restoreSession();

  Future<void> logout();
}
```

### `lib/feature/auth/data/repositories/auth_repository_impl.dart`

```dart
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syrian_dio/syrian_dio.dart';

import '../../../../core/network/network_info.dart';
import '../models/auth_user_model.dart';
import 'auth_failure.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  static const String _cachedUserKey = 'auth.cached_user';

  final DioNetworkClient _client;
  final NetworkInfo _networkInfo;
  final SharedPreferences _prefs;
  final TokenStore _tokenStore;

  AuthRepositoryImpl({
    required DioNetworkClient client,
    required NetworkInfo networkInfo,
    required SharedPreferences prefs,
    required TokenStore tokenStore,
  }) : _client = client,
       _networkInfo = networkInfo,
       _prefs = prefs,
       _tokenStore = tokenStore;

  @override
  Future<Either<AuthFailure, AuthUserModel>> login({
    required String email,
    required String password,
  }) async {
    if (!await _networkInfo.isConnected) {
      return left(
        const AuthFailure(
          message: 'No internet connection.',
          type: NetworkErrorType.noInternet,
        ),
      );
    }

    final result = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      body: <String, dynamic>{
        'email': email,
        'password': password,
      },
      parser: (raw) => raw as Map<String, dynamic>,
    );

    return result.fold(
      (error) => left(_mapNetworkError(error)),
      (json) async {
        final accessToken = json['access_token'] as String;
        final refreshToken = json['refresh_token'] as String?;
        final user = AuthUserModel.fromJson(json['user'] as Map<String, dynamic>);

        await _tokenStore.saveAccessToken(accessToken);
        if (refreshToken != null) {
          await _tokenStore.saveRefreshToken(refreshToken);
        }

        await _prefs.setString(_cachedUserKey, jsonEncode(user.toJson()));
        return right(user);
      },
    );
  }

  @override
  Future<Either<AuthFailure, AuthUserModel?>> restoreSession() async {
    final cached = _prefs.getString(_cachedUserKey);
    if (cached == null) {
      return right(null);
    }

    try {
      final json = jsonDecode(cached) as Map<String, dynamic>;
      return right(AuthUserModel.fromJson(json));
    } catch (_) {
      await _prefs.remove(_cachedUserKey);
      return left(
        const AuthFailure(
          message: 'Corrupted cached user session.',
        ),
      );
    }
  }

  @override
  Future<void> logout() async {
    await _tokenStore.clear();
    await _prefs.remove(_cachedUserKey);
  }

  AuthFailure _mapNetworkError(NetworkError error) {
    switch (error.type) {
      case NetworkErrorType.noInternet:
        return const AuthFailure(
          message: 'No internet connection.',
          type: NetworkErrorType.noInternet,
        );
      case NetworkErrorType.dnsFailure:
        return AuthFailure(
          message: 'Could not resolve API host (${error.host ?? 'unknown host'}).',
          type: NetworkErrorType.dnsFailure,
          technicalDetails: error.rawMessage,
        );
      case NetworkErrorType.timeout:
        return const AuthFailure(
          message: 'Request timed out, please try again.',
          type: NetworkErrorType.timeout,
        );
      case NetworkErrorType.unauthorized:
        return const AuthFailure(
          message: 'Invalid credentials.',
          type: NetworkErrorType.unauthorized,
        );
      case NetworkErrorType.notFound:
        return const AuthFailure(
          message: 'API endpoint was not found.',
          type: NetworkErrorType.notFound,
        );
      case NetworkErrorType.server:
        return const AuthFailure(
          message: 'Server error, please try later.',
          type: NetworkErrorType.server,
        );
      case NetworkErrorType.badResponse:
      case NetworkErrorType.forbidden:
      case NetworkErrorType.cancelled:
      case NetworkErrorType.unknown:
        return AuthFailure(
          message: error.message,
          type: error.type,
          technicalDetails: error.rawMessage,
        );
    }
  }
}
```

## 5) Presentation layer (Cubit)

### `lib/feature/auth/presentation/cubits/auth_state.dart`

```dart
import '../../data/models/auth_user_model.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final AuthUserModel user;

  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}
```

### `lib/feature/auth/presentation/cubits/auth_cubit.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit(this._repository) : super(const AuthInitial());

  Future<void> bootstrap() async {
    final restored = await _repository.restoreSession();
    restored.fold(
      (_) => emit(const AuthUnauthenticated()),
      (user) => user == null
          ? emit(const AuthUnauthenticated())
          : emit(AuthAuthenticated(user)),
    );
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());

    final result = await _repository.login(
      email: email,
      password: password,
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    emit(const AuthUnauthenticated());
  }
}
```

### `lib/feature/auth/presentation/pages/login_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/auth_cubit.dart';
import '../cubits/auth_state.dart';
import '../widgets/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AuthAuthenticated) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Welcome ${state.user.name}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<AuthCubit>().logout(),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );
          }
          return const LoginForm();
        },
      ),
    );
  }
}
```

### `lib/feature/auth/presentation/widgets/login_form.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/auth_cubit.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<AuthCubit>().login(
                  email: _emailController.text.trim(),
                  password: _passwordController.text,
                );
              },
              child: const Text('Login'),
            ),
          ),
        ],
      ),
    );
  }
}
```

## 6) App entry

### `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/get_it.dart';
import 'feature/auth/presentation/cubits/auth_cubit.dart';
import 'feature/auth/presentation/pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlocProvider<AuthCubit>(
        create: (_) => sl<AuthCubit>()..bootstrap(),
        child: const LoginPage(),
      ),
    );
  }
}
```

## 7) Why this works well with `syrian_dio`

- `syrian_dio` gives you a single `Result<T>` and normalized `NetworkError`.
- New DNS behavior is preserved:
  - `NetworkErrorType.dnsFailure` for host lookup issues.
  - `NetworkErrorType.noInternet` for actual connectivity loss.
  - `error.rawMessage` + `error.host` keep technical details for logs/debugging.
- Retry interceptor will skip deterministic DNS failures automatically.

## 8) Production notes

- Keep API `baseUrl` in environment config, not hardcoded.
- Send `technicalDetails` only to logs/crash reporting, not directly to end users.
- If you already have app-level auth interceptors, add them via `extraInterceptors`.
- If your project uses `internet_connection_checker_plus` instead, keep the same `NetworkInfo` abstraction and swap the implementation only.
