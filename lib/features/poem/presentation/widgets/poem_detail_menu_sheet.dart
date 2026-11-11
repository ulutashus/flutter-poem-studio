import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:poem_studio/core/l10n/l10n.dart';
import 'package:poem_studio/core/widgets/app_bottom_sheet.dart';
import 'package:poem_studio/features/poem/domain/entities/poem_entity.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_detail_bloc.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_detail_event.dart';
import 'package:poem_studio/features/poem/presentation/bloc/poem_detail_state.dart';
import 'package:poem_studio/features/poem/presentation/widgets/poem_share_card.dart';
import 'package:poem_studio/features/settings/settings.dart';
import 'package:screenshot/screenshot.dart';

Future<void> showPoemDetailMenuSheet(
  BuildContext context, {
  required VoidCallback onEdit,
}) {
  final detailBloc = context.read<PoemDetailBloc>();
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.textSizeTitle,
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const TextScaleSlider(),
            const SizedBox(height: 16),
            _MenuItem(
              icon: Icons.image_outlined,
              label: context.l10n.shareAsImage,
              onTap: () async {
                Navigator.pop(sheetContext);
                if (detailBloc.state case PoemDetailLoaded(:final poem)) {
                  final bytes = await _captureWithLoading(context, poem);
                  detailBloc.add(PoemDetailImageShareRequested(bytes));
                }
              },
            ),
            _MenuItem(
              icon: Icons.text_fields,
              label: context.l10n.shareAsText,
              onTap: () {
                Navigator.pop(sheetContext);
                detailBloc.add(const PoemDetailTextShareRequested());
              },
            ),
            _MenuItem(
              icon: Icons.edit_outlined,
              label: context.l10n.editAction,
              onTap: () {
                Navigator.pop(sheetContext);
                onEdit();
              },
            ),
            const SizedBox(height: 24),
            const AppSheetCloseButton(),
          ],
        ),
      ),
    ),
  );
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}

Future<Uint8List> _captureWithLoading(
  BuildContext context,
  PoemEntity poem,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    ),
  );
  try {
    return await _captureCard(context, poem);
  } finally {
    navigator.pop();
  }
}

Future<Uint8List> _captureCard(BuildContext context, PoemEntity poem) {
  final mediaQuery = MediaQuery.of(context);
  return ScreenshotController().captureFromLongWidget(
    InheritedTheme.captureAll(
      context,
      MediaQuery(
        data: mediaQuery,
        child: Theme(
          data: Theme.of(context),
          child: Material(child: PoemShareCard(poem: poem)),
        ),
      ),
    ),
    context: context,
    delay: const Duration(milliseconds: 200),
    pixelRatio: mediaQuery.devicePixelRatio,
    constraints: BoxConstraints(maxWidth: mediaQuery.size.width),
  );
}
