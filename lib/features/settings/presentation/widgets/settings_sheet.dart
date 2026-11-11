import 'package:flutter/material.dart';
import 'package:poem_studio/core/l10n/l10n.dart';
import 'package:poem_studio/core/widgets/app_bottom_sheet.dart';
import 'package:poem_studio/features/settings/presentation/widgets/language_selector.dart';
import 'package:poem_studio/features/settings/presentation/widgets/text_scale_slider.dart';

Future<void> showSettingsSheet(BuildContext context) {
  return showAppBottomSheet<void>(
    context: context,
    titleBuilder: (context) => context.l10n.settingsTitle,
    builder: (sheetContext) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sheetContext.l10n.textSizeTitle,
          style: Theme.of(sheetContext).textTheme.labelLarge,
        ),
        const TextScaleSlider(),
        if (AppLocalizations.supportedLocales.length > 1) ...[
          const SizedBox(height: 16),
          Text(
            sheetContext.l10n.languageTitle,
            style: Theme.of(sheetContext).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          const LanguageSelector(),
        ],
      ],
    ),
  );
}
