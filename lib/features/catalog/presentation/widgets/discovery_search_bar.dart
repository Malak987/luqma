import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/store_discovery_cubit.dart';
import '../cubit/store_discovery_state.dart';

/// Pill search field. It filters the stores that are already loaded, because
/// the stores endpoint has no search parameter yet.
class DiscoverySearchBar extends StatefulWidget {
  const DiscoverySearchBar({required this.hintText, super.key});

  final String hintText;

  @override
  State<DiscoverySearchBar> createState() => _DiscoverySearchBarState();
}

class _DiscoverySearchBarState extends State<DiscoverySearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    context.read<StoreDiscoveryCubit>().setSearchQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final copy = AppLocalizations.of(context).catalog;
    final border = OutlineInputBorder(
      borderRadius: AppRadius.pillRadius,
      borderSide: BorderSide(color: colors.border),
    );

    return BlocListener<StoreDiscoveryCubit, StoreDiscoveryState>(
      // Keeps the text in sync when "show all" clears the query.
      listenWhen: (before, after) => before.searchQuery != after.searchQuery,
      listener: (context, state) {
        if (_controller.text.trim() != state.searchQuery) {
          _controller.text = state.searchQuery;
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        child: TextField(
          key: const Key('discovery_search'),
          controller: _controller,
          textInputAction: TextInputAction.search,
          onChanged: context.read<StoreDiscoveryCubit>().setSearchQuery,
          decoration: InputDecoration(
            hintText: widget.hintText,
            filled: true,
            fillColor: colors.surface,
            prefixIcon: Icon(Icons.search_rounded, color: colors.primary),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) => value.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      key: const Key('discovery_search_clear'),
                      tooltip: copy.clearSearch,
                      icon: Icon(Icons.close_rounded, color: colors.mutedText),
                      onPressed: _clear,
                    ),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            border: border,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.pillRadius,
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
