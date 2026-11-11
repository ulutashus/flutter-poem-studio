import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:poem_studio/features/settings/presentation/bloc/text_scale_cubit.dart';

class ReadingTextScale extends StatelessWidget {
  const ReadingTextScale({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextScaleCubit, double>(
      builder: (context, scale) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child,
      ),
    );
  }
}
