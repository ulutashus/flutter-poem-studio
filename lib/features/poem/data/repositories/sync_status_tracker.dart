import 'dart:async';

import 'package:injectable/injectable.dart';

import 'package:poem_studio/features/poem/domain/entities/sync_status.dart';

/// Holds the latest sync status and replays it to every new listener.
@lazySingleton
class SyncStatusTracker {
  final _controller = StreamController<SyncStatus>.broadcast();
  SyncStatus _current = SyncStatus.idle;

  SyncStatus get current => _current;

  Stream<SyncStatus> watch() {
    return Stream.multi((listener) {
      listener.add(_current);
      final subscription = _controller.stream.listen(
        listener.addSync,
        onDone: listener.closeSync,
      );
      listener.onCancel = subscription.cancel;
    });
  }

  void update(SyncStatus status) {
    if (status == _current) return;
    _current = status;
    _controller.add(status);
  }

  @disposeMethod
  Future<void> dispose() => _controller.close();
}
