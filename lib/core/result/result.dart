import 'package:equatable/equatable.dart';

import 'package:poem_studio/core/error/failures.dart';

sealed class Result<T> extends Equatable {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.data);

  final T data;

  @override
  List<Object?> get props => [data];
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
