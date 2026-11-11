import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:poem_studio/core/l10n/l10n.dart';
import 'package:poem_studio/features/poem/domain/entities/sync_status.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_sync_cubit.dart';

class PoemSyncIndicator extends StatelessWidget {
  const PoemSyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PoemSyncCubit, SyncStatus>(
      builder: (context, status) => switch (status) {
        SyncStatus.idle => const SizedBox.shrink(),
        SyncStatus.syncing => Tooltip(
          message: context.l10n.syncingTooltip,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        SyncStatus.failed => IconButton(
          icon: const Icon(Icons.cloud_off_outlined),
          tooltip: context.l10n.syncFailedTooltip,
          onPressed: context.read<PoemSyncCubit>().retry,
        ),
      },
    );
  }
}
