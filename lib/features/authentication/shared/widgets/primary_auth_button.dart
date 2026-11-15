import 'package:flutter/material.dart';

import '../../../../core/widgets/app_button.dart';

class PrimaryAuthButton extends StatelessWidget {
  const PrimaryAuthButton({
    required this.text,
    required this.onPressed,
    super.key,
    this.loading = false,
    this.enabled = true,
    this.semanticLabel,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final bool enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: text,
      width: double.infinity,
      loading: loading,
      enabled: enabled,
      onPressed: onPressed,
      semanticLabel: semanticLabel,
    );
  }
}
