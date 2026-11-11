import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/core/l10n/generated/app_localizations.dart';

extension FailureMessage on Failure {
  String message(AppLocalizations l10n) => switch (this) {
    NetworkFailure() => l10n.errorNetwork,
    ServerFailure() => l10n.errorServer,
    UnauthorizedFailure() => l10n.errorUnauthorized,
    NotFoundFailure() => l10n.errorNotFound,
    StorageFailure() => l10n.errorStorage,
    ValidationFailure() => l10n.errorValidation,
  };
}
