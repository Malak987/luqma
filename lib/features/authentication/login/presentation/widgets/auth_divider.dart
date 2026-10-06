import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_divider.dart';

class AuthDivider extends StatelessWidget {
  const AuthDivider({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppLabeledDivider(label: label);
  }
}
