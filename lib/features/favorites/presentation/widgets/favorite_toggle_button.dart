import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/favorites_cubit.dart';
import '../cubit/favorites_state.dart';

/// Reusable, API-backed menu-item heart. It contains no endpoint knowledge:
/// the shell-scoped [FavoritesCubit] is the only owner of membership and
/// mutations. Outside an authenticated shell it degrades to a disabled visual
/// affordance, which keeps catalog widgets independently renderable in tests.
class FavoriteToggleButton extends StatefulWidget {
  const FavoriteToggleButton({
    required this.menuItemId,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 44,
    super.key,
  });

  final String menuItemId;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;

  @override
  State<FavoriteToggleButton> createState() => _FavoriteToggleButtonState();
}

class _FavoriteToggleButtonState extends State<FavoriteToggleButton> {
  @override
  void initState() {
    super.initState();
    _ensureStatus();
  }

  @override
  void didUpdateWidget(covariant FavoriteToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.menuItemId.toLowerCase() != widget.menuItemId.toLowerCase()) {
      _ensureStatus();
    }
  }

  FavoritesCubit? _findFavoritesCubit(BuildContext context) {
    if (context.findAncestorWidgetOfExactType<BlocProvider<FavoritesCubit>>() ==
        null) {
      return null;
    }
    return BlocProvider.of<FavoritesCubit>(context, listen: false);
  }

  void _ensureStatus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _findFavoritesCubit(context)?.ensureFavoriteStatus(widget.menuItemId);
    });
  }

  Future<void> _toggle(BuildContext context) async {
    final cubit = _findFavoritesCubit(context);
    if (cubit == null) return;
    final result = await cubit.toggle(widget.menuItemId);
    if (!mounted || result == FavoriteMutationResult.busy) return;
    final copy = AppLocalizations.of(context).favorites;
    final message = switch (result) {
      FavoriteMutationResult.success =>
        cubit.state.isFavorite(widget.menuItemId) ? copy.added : copy.removed,
      FavoriteMutationResult.synchronizationFailed => copy.synchronizationFailed,
      FavoriteMutationResult.failed => copy.actionFailed,
      FavoriteMutationResult.busy => '',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _findFavoritesCubit(context);
    if (cubit == null) {
      return _FavoriteButtonVisual(
        menuItemId: widget.menuItemId,
        favorite: false,
        checking: false,
        enabled: false,
        size: widget.size,
        backgroundColor: widget.backgroundColor,
        foregroundColor: widget.foregroundColor,
      );
    }
    return BlocSelector<FavoritesCubit, FavoritesState, (bool?, bool, bool)>(
      selector: (state) => (
        state.knowsFavorite(widget.menuItemId)
            ? state.isFavorite(widget.menuItemId)
            : null,
        state.isChecking(widget.menuItemId),
        state.isMutating,
      ),
      builder: (context, view) => _FavoriteButtonVisual(
        menuItemId: widget.menuItemId,
        favorite: view.$1 ?? false,
        checking: view.$2,
        enabled: !view.$2 && !view.$3,
        size: widget.size,
        backgroundColor: widget.backgroundColor,
        foregroundColor: widget.foregroundColor,
        onPressed: () => _toggle(context),
      ),
    );
  }
}

class _FavoriteButtonVisual extends StatelessWidget {
  const _FavoriteButtonVisual({
    required this.menuItemId,
    required this.favorite,
    required this.checking,
    required this.enabled,
    required this.size,
    this.backgroundColor,
    this.foregroundColor,
    this.onPressed,
  });

  final String menuItemId;
  final bool favorite;
  final bool checking;
  final bool enabled;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final copy = AppLocalizations.of(context).favorites;
    final activeColor = foregroundColor ?? colors.primary;
    final effectiveBackground = backgroundColor ?? colors.surface;
    final tooltip = favorite ? copy.remove : copy.add;
    final canPress = enabled && onPressed != null;

    return Semantics(
      button: true,
      selected: favorite,
      enabled: canPress,
      label: tooltip,
      child: Material(
        color: effectiveBackground,
        shape: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: IconButton(
            key: ValueKey('favorite_toggle_${menuItemId.toLowerCase()}'),
            onPressed: canPress ? onPressed : null,
            constraints: BoxConstraints.tightFor(width: size, height: size),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: checking
                ? SizedBox.square(
                    dimension: size * .42,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: activeColor,
                    ),
                  )
                : Icon(
                    favorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: activeColor,
                  ),
          ),
        ),
      ),
    );
  }
}
