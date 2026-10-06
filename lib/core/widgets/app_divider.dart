import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppLabeledDivider extends StatelessWidget {
  const AppLabeledDivider({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final semanticColors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return Row(
      children: <Widget>[
        Expanded(
          child: Divider(color: semanticColors.divider, height: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Divider(color: semanticColors.divider, height: 1),
        ),
      ],
    );
  }
}
