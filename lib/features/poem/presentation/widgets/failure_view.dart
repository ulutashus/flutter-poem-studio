import 'package:flutter/material.dart';

import 'package:poem_studio/core/error/failures.dart';
import 'package:poem_studio/core/l10n/failure_messages.dart';
import 'package:poem_studio/core/l10n/l10n.dart';

class FailureView extends StatelessWidget {
  const FailureView({super.key, required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(failure.message(context.l10n), textAlign: TextAlign.center),
      ),
    );
  }
}
