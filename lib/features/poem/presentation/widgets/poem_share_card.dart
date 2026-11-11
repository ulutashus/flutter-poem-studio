import 'package:flutter/material.dart';

import 'package:poem_studio/core/theme/app_theme.dart';
import 'package:poem_studio/features/poem/domain/entities/poem_entity.dart';

class PoemShareCard extends StatelessWidget {
  const PoemShareCard({super.key, required this.poem});

  final PoemEntity poem;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cream,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            poem.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            poem.content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
