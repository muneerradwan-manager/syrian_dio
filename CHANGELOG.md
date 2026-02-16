## 0.0.4

- Inlined the full GetIt + Cubit + Dartz architecture integration guide directly in the main `README.md`.
- Added the same integration guide to `example/README.md` so it shows on pub.dev's Example tab.
- Updated documentation dependency snippets to `syrian_dio: ^0.0.4`.

## 0.0.3

- Added `NetworkErrorType.dnsFailure` to distinguish DNS lookup failures from real connectivity loss.
- Improved Dio error mapping for `connectionError`:
  - DNS lookup failures now map to `dnsFailure`.
  - Offline connectivity failures map to `noInternet`.
  - Other connection failures map to `unknown` with clearer context.
- Extended `NetworkError` with debug-friendly metadata: `rawMessage`, `host`, and `uri`.
- Updated retry behavior to skip deterministic DNS failures (no useless retries for typo/invalid hostnames).
- Added tests covering: offline connectivity, invalid hostname, timeout, 404, 500, and DNS no-retry behavior.
- Added full architecture integration guide for `get_it` + `flutter_bloc` + `dartz` + `shared_preferences` + `flutter_secure_storage` + `internet_connection_checker` in `doc/get_it_cubit_dartz_auth_example.md`.

## 0.0.2

- Added full README usage documentation with quick start, request examples, and refresh-token flow.
- Added comprehensive public API dartdoc comments across exported types.
- Fixed `DioNetworkClient` inheritance to correctly use `extends NetworkClient`.
- Added and verified runnable `example/` app structure for Android, Web, and Windows.
- Added basic package test coverage for `Result<T>` helpers.
- Updated package metadata links (`homepage`, `repository`, `issue_tracker`) for pub.dev verification.

## 0.0.1

- Initial package skeleton.
