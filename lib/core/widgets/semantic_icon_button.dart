import 'package:flutter/material.dart';

/// Small shared wrapper that guarantees a comfortable touch target while the
/// visual icon can remain compact enough for authentication fields.
class SemanticIconButton extends StatelessWidget {
  const SemanticIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    super.key,
    this.color,
    this.iconSize,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color? color;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: iconSize,
      color: color,
      constraints: const BoxConstraints(
        minWidth: 48,
        minHeight: 48,
      ),
      padding: EdgeInsets.zero,
      icon: Icon(icon),
    );
  }
}
