import 'package:flutter/material.dart';

import 'package:poem_studio/core/l10n/l10n.dart';

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required String Function(BuildContext context) titleBuilder,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Text(
                titleBuilder(sheetContext),
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: builder(sheetContext),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: AppSheetCloseButton(),
            ),
          ],
        ),
      ),
    ),
  );
}

class AppSheetCloseButton extends StatelessWidget {
  const AppSheetCloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      onPressed: () => Navigator.pop(context),
      child: Text(context.l10n.closeButton),
    );
  }
}
