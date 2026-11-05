import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/map/tile_provider_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/di/service_locator.dart';
import '../../../location/domain/entities/location_coordinates.dart';
import '../cubit/map_picker_cubit.dart';
import '../cubit/map_picker_state.dart';

/// Interactive map location picker.
///
/// Fills the screen with a pannable map, a fixed centre pin, recenter and
/// confirm controls. Uses [TileProviderConfig.osmUrlTemplate] for tiles and
/// shows the required OSM attribution. No prefetch/offline cache, no paid keys.
/// Initial position reuses existing location use-cases with Sohag fallback.
class MapLocationPickerPage extends StatelessWidget {
  const MapLocationPickerPage({
    super.key,
    this.onConfirmed,
    this.mapBuilder,
  });

  /// Called when the user confirms a location. If null, the page pops with
  /// the coordinates as a navigation result (typed forward for next phase).
  final ValueChanged<LocationCoordinates>? onConfirmed;

  /// For tests: builds the map area. When null, the real FlutterMap is used.
  final Widget Function(
    BuildContext context,
    LocationCoordinates center,
    ValueChanged<LatLng> onMapMoved,
    bool isDark,
  )? mapBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MapPickerCubit>(
      create: (_) => sl<MapPickerCubit>()..initialize(),
      child: _MapLocationPickerView(
        onConfirmed: onConfirmed,
        mapBuilder: mapBuilder,
      ),
    );
  }
}

class _MapLocationPickerView extends StatefulWidget {
  const _MapLocationPickerView({this.onConfirmed, this.mapBuilder});

  final ValueChanged<LocationCoordinates>? onConfirmed;
  final Widget Function(
    BuildContext context,
    LocationCoordinates center,
    ValueChanged<LatLng> onMapMoved,
    bool isDark,
  )? mapBuilder;

  @override
  State<_MapLocationPickerView> createState() => _MapLocationPickerViewState();
}

class _MapLocationPickerViewState extends State<_MapLocationPickerView> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _moveCamera(LocationCoordinates coords) {
    try {
      _mapController.move(
        LatLng(coords.latitude, coords.longitude),
        15,
      );
    } catch (_) {
      // Controller may not be attached yet (e.g., in tests with fake builder)
    }
  }

  String _localizedError(BuildContext context, String? code) {
    if (code == null) return '';
    final l10n = AppLocalizations.of(context).address;
    if (code == 'service_disabled') return l10n.mapPickerErrorServiceDisabled;
    if (code == 'permission_denied') return l10n.mapPickerErrorPermissionDenied;
    if (code == 'permission_permanently_denied') {
      return l10n.mapPickerErrorPermanentlyDenied;
    }
    if (code.startsWith('retrieval_failed')) {
      return l10n.mapPickerErrorRetrievalFailed;
    }
    if (code == 'permission_required') {
      return l10n.mapPickerErrorPermissionDenied;
    }
    return l10n.mapPickerErrorRetrievalFailed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context).address;
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Single deterministic camera-update mechanism:
    // - Initial GPS success (loading -> ready with device)
    // - Recenter success (locating -> ready with device)
    // Manual moves (ready -> ready) are not animated to avoid overwrite.
    return BlocListener<MapPickerCubit, MapPickerState>(
      listenWhen: (prev, curr) =>
          (prev.status == MapPickerStatus.loading ||
              prev.status == MapPickerStatus.locating) &&
          curr.status == MapPickerStatus.ready &&
          !curr.isFallback &&
          prev.selected != curr.selected,
      listener: (ctx, st) => _moveCamera(st.selected),
      child: BlocBuilder<MapPickerCubit, MapPickerState>(
        builder: (context, state) {
          return Scaffold(
            key: const Key('map_picker_page'),
            backgroundColor: colors.background,
            appBar: AppBar(
              backgroundColor: colors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: Text(
                l10n.mapPickerTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.headingText,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: colors.headingText),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            body: Column(
              children: [
                // Instructions
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    l10n.mapPickerInstructions,
                    key: const Key('map_picker_instructions'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.mutedText,
                        ),
                  ),
                ),
                // Subtle fallback indicator
                if (state.isFallback && state.isReady)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    child: Container(
                      key: const Key('map_picker_fallback_indicator'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: colors.elevatedSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_off_outlined,
                            size: 16,
                            color: colors.mutedText,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              l10n.mapPickerFallbackNotice,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: colors.mutedText),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Map area
                Expanded(
                  child: Stack(
                    children: [
                      // Map or loading
                      if (state.isLoading)
                        Center(
                          key: const Key('map_picker_loading'),
                          child: CircularProgressIndicator(
                            color: colors.primary,
                          ),
                        )
                      else
                        _buildMapArea(
                          context,
                          state.selected,
                          colors,
                          isDark,
                          state,
                        ),
                      // Recenter control
                      PositionedDirectional(
                        top: AppSpacing.md,
                        end: AppSpacing.md,
                        child: _RecenterButton(
                          isLocating: state.isLocating,
                          onPressed: () =>
                              context.read<MapPickerCubit>().recenter(),
                        ),
                      ),
                      // Attribution — RTL-aware, always visible
                      PositionedDirectional(
                        start: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                        child: Container(
                          key: const Key('map_picker_attribution'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.mapPickerAttribution,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colors.mutedText,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ),
                      // Error banner
                      if (state.errorMessage != null)
                        Positioned(
                          left: AppSpacing.md,
                          right: AppSpacing.md,
                          bottom: AppSpacing.md,
                          child: Container(
                            key: const Key('map_picker_error'),
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: colors.elevatedSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            child: Text(
                              _localizedError(context, state.errorMessage),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Bottom confirmation panel
                Container(
                  key: const Key('map_picker_bottom_panel'),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(
                      top: BorderSide(color: colors.border),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Coordinates display
                        Text(
                          l10n.mapPickerCoordinatesLabel(
                            state.selected.latitude,
                            state.selected.longitude,
                          ),
                          key: const Key('map_picker_coordinates'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.mutedText,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        // Distinguish fallback vs device
                        Text(
                          state.isFallback
                              ? l10n.mapPickerIsApproximateLabel
                              : state.selected.isDeviceDetected
                                  ? l10n.mapPickerIsDeviceLabel
                                  : l10n.mapPickerConfirm,
                          key: const Key('map_picker_source_label'),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: state.isFallback
                                    ? colors.mutedText
                                    : colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            key: const Key('map_picker_confirm_button'),
                            onPressed: state.isLoading || state.isLocating
                                ? null
                                : () {
                                    context
                                        .read<MapPickerCubit>()
                                        .confirmSelection();
                                    final coords = context
                                        .read<MapPickerCubit>()
                                        .state
                                        .selected;
                                    if (widget.onConfirmed != null) {
                                      widget.onConfirmed!(coords);
                                    } else {
                                      // Typed result for next phase
                                      Navigator.of(context).pop(coords);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                            ),
                            child: Text(l10n.mapPickerConfirm),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      ),
    );
  }

  Widget _buildMapArea(
    BuildContext context,
    LocationCoordinates center,
    AppSemanticColors colors,
    bool isDark,
    MapPickerState state,
  ) {
    if (widget.mapBuilder != null) {
      return widget.mapBuilder!(
        context,
        center,
        (latLng) => context.read<MapPickerCubit>().onMapMoved(latLng),
        isDark,
      );
    }

    return Stack(
      key: const Key('map_picker_map'),
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(center.latitude, center.longitude),
            initialZoom: 14,
            minZoom: 3,
            maxZoom: 18,
            onMapEvent: (event) {
              // Only update when movement ends, avoid continuous emissions
              if (event is MapEventMoveEnd) {
                context.read<MapPickerCubit>().onMapMoved(event.camera.center);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: TileProviderConfig.osmUrlTemplate,
              userAgentPackageName: 'com.example.luqma_app',
              // No caching/prefetching per requirements
            ),
          ],
        ),
        // Fixed centre pin
        const Center(
          child: _CenterPin(),
        ),
      ],
    );
  }
}

class _CenterPin extends StatelessWidget {
  const _CenterPin();

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            key: const Key('map_picker_center_pin'),
            size: 48,
            color: colors.primary,
            semanticLabel: 'Selected location pin',
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecenterButton extends StatelessWidget {
  const _RecenterButton({required this.isLocating, required this.onPressed});

  final bool isLocating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final l10n = AppLocalizations.of(context).address;
    return Material(
      color: colors.elevatedSurface,
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: isLocating ? null : onPressed,
        child: Container(
          key: const Key('map_picker_recenter_button'),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.border),
          ),
          child: Center(
            child: isLocating
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  )
                : Icon(
                    Icons.my_location_rounded,
                    color: colors.primary,
                    size: 22,
                    semanticLabel: l10n.mapPickerRecenterSemanticLabel,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Exposed for tests to verify tile config without importing map internals.
class MapPickerTestHelper {
  static const String attribution = TileProviderConfig.attribution;
  static const String urlTemplate = TileProviderConfig.osmUrlTemplate;
}
