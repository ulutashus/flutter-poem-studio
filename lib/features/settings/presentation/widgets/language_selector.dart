import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:poem_studio/core/l10n/l10n.dart';
import 'package:poem_studio/features/settings/presentation/bloc/locale_cubit.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  // Language names are shown in their own language.
  static const _nativeNames = {'en': 'English', 'tr': 'Türkçe'};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, selected) => SegmentedButton<Locale>(
        showSelectedIcon: false,
        segments: [
          for (final locale in AppLocalizations.supportedLocales)
            ButtonSegment(
              value: locale,
              label: Text(_nativeNames[locale.languageCode] ?? ''),
            ),
        ],
        selected: {selected},
        onSelectionChanged: (values) =>
            context.read<LocaleCubit>().setLocale(values.first),
      ),
    );
  }
}
