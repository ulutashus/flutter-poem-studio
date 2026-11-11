import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/core/network/dio_failure_mapper.dart';

void main() {
  final options = RequestOptions();

  DioException withStatus(int code) => DioException.badResponse(
    statusCode: code,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: code),
  );

  test('maps a missing response to NetworkFailure', () {
    final error = DioException.connectionError(
      requestOptions: options,
      reason: 'offline',
    );
    expect(error.toFailure(), const NetworkFailure());
  });

  test('maps status codes to typed failures', () {
    expect(withStatus(401).toFailure(), const UnauthorizedFailure());
    expect(withStatus(403).toFailure(), const UnauthorizedFailure());
    expect(withStatus(404).toFailure(), const NotFoundFailure());
    expect(withStatus(500).toFailure(), const ServerFailure());
    expect(withStatus(409).toFailure(), const ServerFailure());
  });
}
