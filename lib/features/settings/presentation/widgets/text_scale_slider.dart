import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:poem_studio/features/settings/domain/entities/text_scale.dart';
import 'package:poem_studio/features/settings/presentation/bloc/text_scale_cubit.dart';

class TextScaleSlider extends StatelessWidget {
  const TextScaleSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextScaleCubit, double>(
      builder: (context, scale) => Row(
        children: [
          const Text('A', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Slider(
              value: scale,
              min: TextScale.min,
              max: TextScale.max,
              divisions: TextScale.steps,
              label: '${(scale * 100).round()}%',
              onChanged: context.read<TextScaleCubit>().setScale,
            ),
          ),
          const Text('A', style: TextStyle(fontSize: 28)),
        ],
      ),
    );
  }
}
