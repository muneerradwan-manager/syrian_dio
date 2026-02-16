import 'package:flutter/material.dart';
import 'package:syrian_dio/syrian_dio.dart';
import 'secure_token_store.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final SecureTokenStore tokenStore;
  late final DioNetworkClient client;

  String output = 'Tap button to call API';

  @override
  void initState() {
    super.initState();
    tokenStore = SecureTokenStore();

    client = DioNetworkClient(
      config: DioConfig(
        baseUrl: 'https://dummyjson.com', // مثال REST مجاني
        tokenProvider: () => tokenStore.getAccessToken(),
        onUnauthorized: () async {
          await tokenStore.clear();
          setState(() => output = 'Unauthorized -> cleared tokens (go login)');
        },
      ),
      enableRetry: true,
      enableLogging: true,
      enableRefreshToken: false, // dummyjson ما عنده refresh عملي
      // لو عندك refresh حقيقي فعّل التالي:
      // enableRefreshToken: true,
      // tokenStore: tokenStore,
      // refreshCall: ({required refreshToken}) async {
      //   final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      //   final res = await refreshDio.post('/auth/refresh', data: {'refresh_token': refreshToken});
      //   final data = res.data as Map<String, dynamic>;
      //   return RefreshResult(
      //     accessToken: data['access_token'] as String,
      //     refreshToken: data['refresh_token'] as String?,
      //   );
      // },
    );
  }

  Future<void> callApi() async {
    final res = await client.get<Map<String, dynamic>>(
      '/users/1',
      parser: (raw) => raw as Map<String, dynamic>,
    );

    res.fold(
      (e) => setState(() => output = 'Error: $e'),
      (data) => setState(() => output = 'OK: ${data['firstName']} ${data['lastName']}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('syrian_dio example')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(output),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: callApi,
                child: const Text('Call API'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
