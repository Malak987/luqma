import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/app_text_field.dart';

/// The Home search entry point.
///
/// A single comfortable field: search glyph, localized placeholder, and a clear
/// action that only appears once there is something to clear. The trailing
/// filter affordance stays omitted until filtering exists, so the field never
/// implies a fake action.
class HomeSearchBar extends StatefulWidget {
  const HomeSearchBar({
    required this.hintText,
    this.clearTooltip,
    this.backgroundColor,
    this.onSubmitted,
    super.key,
  });

  final String hintText;

  /// Tooltip for the clear action. Callers pass the localized string.
  final String? clearTooltip;

  /// Field fill. Defaults to the surface colour of the current theme.
  final Color? backgroundColor;

  final ValueChanged<String>? onSubmitted;

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  /// One fixed field height for every state: the clear action appears and
  /// disappears inside this box, so typing never resizes the header.
  static const double _fieldHeight = 56;

  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    final hasText = value.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _clear() {
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return Container(
      key: const Key('home_search_bar'),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? colors.surface,
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: colors.border.withValues(alpha: .6)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: .14),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AppTextField(
        controller: _controller,
        hintText: widget.hintText,
        semanticLabel: widget.hintText,
        prefixIcon: Icon(
          Icons.search_rounded,
          color: colors.mutedText,
          size: AppSizes.iconLarge,
        ),
        suffixIcon: _hasText
            ? IconButton(
                key: const Key('home_search_clear'),
                tooltip: widget.clearTooltip,
                onPressed: _clear,
                icon: Icon(
                  Icons.close_rounded,
                  color: colors.mutedText,
                  size: AppSizes.iconMedium,
                ),
              )
            : null,
        iconSize: AppSizes.iconMedium,
        height: _fieldHeight,
        textInputAction: TextInputAction.search,
        onChanged: _handleChanged,
        onSubmitted: widget.onSubmitted,
        backgroundColor: Colors.transparent,
        borderColor: Colors.transparent,
        focusedBorderColor: Colors.transparent,
        borderRadius: AppRadius.pillRadius,
      ),
    );
  }
}
