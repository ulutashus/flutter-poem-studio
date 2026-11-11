import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure();

  @override
  List<Object?> get props => [];
}

final class ServerFailure extends Failure {
  const ServerFailure();
}

final class NetworkFailure extends Failure {
  const NetworkFailure();
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure();
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

final class StorageFailure extends Failure {
  const StorageFailure();
}

final class ValidationFailure extends Failure {
  const ValidationFailure();
}
