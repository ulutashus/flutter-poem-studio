import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:poem_studio/features/poem/domain/entities/sync_status.dart';
import 'package:poem_studio/features/poem/domain/repositories/poem_repository.dart';

@injectable
class PoemSyncCubit extends Cubit<SyncStatus> {
  PoemSyncCubit(this._repository) : super(SyncStatus.idle);

  final PoemRepository _repository;
  StreamSubscription<SyncStatus>? _subscription;

  /// Mirrors the repository's sync status and runs the initial sync.
  Future<void> start() async {
    await _subscription?.cancel();
    _subscription = _repository.watchSyncStatus().listen(emit);
    await _repository.syncPoems();
  }

  Future<void> retry() async {
    await _repository.syncPoems();
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
