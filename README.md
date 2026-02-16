# syrian_dio

A Flutter networking layer on top of Dio with:
- `Result<T>` response model (no exception-based flow in app code)
- Unified `NetworkError` mapping
- Retry interceptor with exponential backoff
- Automatic auth header injection
- Optional refresh-token flow
- Request/response logging

## Installation

```yaml
dependencies:
  syrian_dio: ^0.0.3
```

Then:

```bash
flutter pub get
```

## Import

```dart
import 'package:syrian_dio/syrian_dio.dart';
```

## Quick Start

```dart
import 'package:syrian_dio/syrian_dio.dart';

final client = DioNetworkClient(
  config: DioConfig(
    baseUrl: 'https://dummyjson.com',
    onUnauthorized: () {
      // Handle forced logout / session expiry.
    },
  ),
  enableRetry: true,
  maxRetries: 3,
  enableLogging: true,
);
```

### Basic GET request

```dart
class User {
  final int id;
  final String firstName;
  final String lastName;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
    );
  }
}

Future<void> loadUser(DioNetworkClient client) async {
  final result = await client.get<User>(
    '/users/1',
    parser: (raw) => User.fromJson(raw as Map<String, dynamic>),
  );

  result.fold(
    (error) => print('Request failed: ${error.type} - ${error.message}'),
    (user) => print('Hello ${user.firstName} ${user.lastName}'),
  );
}
```

### Basic POST request

```dart
Future<void> createUser(DioNetworkClient client) async {
  final result = await client.post<Map<String, dynamic>>(
    '/users/add',
    body: {
      'firstName': 'John',
      'lastName': 'Doe',
    },
    parser: (raw) => raw as Map<String, dynamic>,
  );

  result.fold(
    (error) => print('Create failed: ${error.message}'),
    (data) => print('Created user id: ${data['id']}'),
  );
}
```

## Full Example (Auth + Refresh)

```dart
import 'package:dio/dio.dart';
import 'package:syrian_dio/syrian_dio.dart';

class InMemoryTokenStore implements TokenStore {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> saveAccessToken(String token) async {
    _accessToken = token;
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    _refreshToken = token;
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
  }
}

Future<DioNetworkClient> buildClient() async {
  final tokenStore = InMemoryTokenStore();
  final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));

  return DioNetworkClient(
    config: DioConfig(
      baseUrl: 'https://api.example.com',
      tokenProvider: () => tokenStore.getAccessToken(),
      onUnauthorized: () async {
        await tokenStore.clear();
        print('Session expired. Please log in again.');
      },
    ),
    enableRetry: true,
    maxRetries: 3,
    enableLogging: true,
    logBody: false,
    enableRefreshToken: true,
    tokenStore: tokenStore,
    refreshCall: ({required refreshToken}) async {
      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = response.data as Map<String, dynamic>;
      return RefreshResult(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String?,
      );
    },
  );
}

Future<void> fetchProfile(DioNetworkClient client) async {
  final result = await client.get<Map<String, dynamic>>(
    '/profile',
    parser: (raw) => raw as Map<String, dynamic>,
  );

  result.fold(
    (error) {
      switch (error.type) {
        case NetworkErrorType.noInternet:
          print('No internet connection.');
          break;
        case NetworkErrorType.timeout:
          print('Request timed out.');
          break;
        case NetworkErrorType.unauthorized:
          print('Unauthorized.');
          break;
        default:
          print('Request failed: ${error.message}');
      }
    },
    (profile) => print('Profile loaded: $profile'),
  );
}
```

## Constructor Options

`DioNetworkClient` supports:
- `config` (`DioConfig`): base URL, timeouts, token provider, unauthorized callback
- `dio` (`Dio?`): optional custom Dio instance
- `enableLogging` / `logBody`
- `enableRetry` / `maxRetries`
- `enableRefreshToken`
- `tokenStore` + `refreshCall` (required when refresh is enabled)
- `onRefreshFailed`
- `refreshPathContains`
- `extraInterceptors`

## Architecture Example (GetIt + Cubit + Dartz)

For a full production-style integration using:
- `get_it`
- `flutter_bloc` (`Cubit`)
- `dartz` (`Either`)
- `shared_preferences`
- `flutter_secure_storage`
- `internet_connection_checker`

See:

`doc/get_it_cubit_dartz_auth_example.md`

## Error Model

Possible `NetworkErrorType` values:
- `noInternet`
- `dnsFailure`
- `timeout`
- `cancelled`
- `unauthorized`
- `forbidden`
- `notFound`
- `badResponse`
- `server`
- `unknown`

## Run Included Example App

From repository root:

```bash
cd example
flutter pub get
flutter run -d windows
```

You can also run on Android/Web if those toolchains are configured.
