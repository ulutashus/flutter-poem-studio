import 'package:dio/dio.dart';

import 'package:poem_studio/core/error/failures.dart';

extension DioFailureMapper on DioException {
  Failure toFailure() {
    final status = response?.statusCode;
    return switch (status) {
      null => const NetworkFailure(),
      401 || 403 => const UnauthorizedFailure(),
      404 => const NotFoundFailure(),
      _ => const ServerFailure(),
    };
  }
}
