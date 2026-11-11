import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poem_studio/core/network/retry_interceptor.dart';

/// Replays a scripted sequence: an `int` is an HTTP status, a [DioExceptionType] is thrown.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._script);

  final List<Object> _script;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final step = _script[calls++];
    if (step is DioExceptionType) {
      throw DioException(requestOptions: options, type: step);
    }
    return ResponseBody.fromString('{}', step as int);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;

  _ScriptedAdapter script(List<Object> steps) {
    final adapter = _ScriptedAdapter(steps);
    dio = Dio()..httpClientAdapter = adapter;
    dio.interceptors.add(RetryInterceptor(dio: dio, baseDelay: Duration.zero));
    return adapter;
  }

  test('retries transient failures until a request succeeds', () async {
    final adapter = script([503, DioExceptionType.connectionError, 200]);

    final response = await dio.get<dynamic>('https://api.test/poems');

    expect(response.statusCode, 200);
    expect(adapter.calls, 3);
  });

  test('gives up after the maximum number of attempts', () async {
    final adapter = script([503, 503, 503, 200]);

    await expectLater(
      dio.get<dynamic>('https://api.test/poems'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          503,
        ),
      ),
    );
    expect(adapter.calls, 3);
  });

  test('does not retry client errors', () async {
    final adapter = script([404, 200]);

    await expectLater(
      dio.get<dynamic>('https://api.test/poems'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.calls, 1);
  });

  test('classifies timeouts and 5xx as transient, 4xx as permanent', () {
    final options = RequestOptions();
    DioException withStatus(int code) => DioException.badResponse(
      statusCode: code,
      requestOptions: options,
      response: Response(requestOptions: options, statusCode: code),
    );

    expect(
      RetryInterceptor.isTransient(
        DioException.receiveTimeout(
          timeout: Duration.zero,
          requestOptions: options,
        ),
      ),
      isTrue,
    );
    expect(RetryInterceptor.isTransient(withStatus(500)), isTrue);
    expect(RetryInterceptor.isTransient(withStatus(422)), isFalse);
  });
}
