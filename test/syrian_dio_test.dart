import 'package:flutter_test/flutter_test.dart';
import 'package:syrian_dio/syrian_dio.dart';

void main() {
  test('result helpers expose state flags', () {
    const ok = Ok<int>(42);
    const err = Err<int>(
      NetworkError(
        type: NetworkErrorType.unknown,
        message: 'boom',
      ),
    );

    expect(ok.isOk, isTrue);
    expect(ok.isErr, isFalse);
    expect(err.isOk, isFalse);
    expect(err.isErr, isTrue);
  });
}
