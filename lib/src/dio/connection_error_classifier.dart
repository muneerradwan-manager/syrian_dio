import 'package:dio/dio.dart';

/// Normalized classification for connection-level Dio failures.
enum ConnectionFailureKind { dnsFailure, noInternet, other }

final List<RegExp> _dnsFailurePatterns = <RegExp>[
  RegExp(r'failed host lookup', caseSensitive: false),
  RegExp(r'temporary failure in name resolution', caseSensitive: false),
  RegExp(r'no address associated with hostname', caseSensitive: false),
  RegExp(r'name or service not known', caseSensitive: false),
  RegExp(r'nodename nor servname provided', caseSensitive: false),
  RegExp(r'getaddrinfo', caseSensitive: false),
  RegExp(r'wsahost_not_found', caseSensitive: false),
  RegExp(r'errno\s*=\s*11001', caseSensitive: false),
];

final List<RegExp> _offlinePatterns = <RegExp>[
  RegExp(r'network is unreachable', caseSensitive: false),
  RegExp(r'network unreachable', caseSensitive: false),
  RegExp(r'no route to host', caseSensitive: false),
  RegExp(r'host is unreachable', caseSensitive: false),
  RegExp(r'network is down', caseSensitive: false),
  RegExp(r'failed to connect.*network', caseSensitive: false),
  RegExp(r'errno\s*=\s*101', caseSensitive: false),
  RegExp(r'errno\s*=\s*113', caseSensitive: false),
];

/// Extracts the most useful low-level message for diagnostics.
String? extractRawDioMessage(DioException e) {
  final message = e.message?.trim();
  final error = e.error?.toString().trim();

  if ((message == null || message.isEmpty) &&
      (error == null || error.isEmpty)) {
    return null;
  }
  if (message == null || message.isEmpty) {
    return error;
  }
  if (error == null || error.isEmpty || error == message) {
    return message;
  }
  return '$message | $error';
}

/// Classifies connection failures into DNS/offline/other buckets.
ConnectionFailureKind classifyConnectionFailure(DioException e) {
  if (e.type != DioExceptionType.connectionError) {
    return ConnectionFailureKind.other;
  }

  final raw = extractRawDioMessage(e);
  if (raw == null || raw.isEmpty) {
    return ConnectionFailureKind.other;
  }

  if (_dnsFailurePatterns.any((pattern) => pattern.hasMatch(raw))) {
    return ConnectionFailureKind.dnsFailure;
  }

  if (_offlinePatterns.any((pattern) => pattern.hasMatch(raw))) {
    return ConnectionFailureKind.noInternet;
  }

  return ConnectionFailureKind.other;
}
