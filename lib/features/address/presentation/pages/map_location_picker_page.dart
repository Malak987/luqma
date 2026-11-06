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
/// confirm controls. Uses [TileProviderConfig.resolveForCurrent] (Geoapify
/// premium when `GEOAPIFY_API_KEY` is set, OSM debug fallback, or localized
/// configuration error in release without key) for tiles and shows the
/// required attribution per provider. No prefetch/bulk/offline download.
/// Caching: flutter_map >=8.2.0 `NetworkTileProvider` + `BuiltInMapCachingProvider`
/// (native, 1 GB soft limit, respects Cache-Control/ETag) / browser HTTP cache
/// (web); see [TileProviderConfig.cachingNote]. User-Agent: Android
/// `com.example.luqma_app` (iOS `com.example.luqmaApp` differs, see
/// [TileProviderConfig.userAgentPackageName]). Initial position reuses
/// existing location use-cases with Sohag fallback.
class MapLocationPickerPage extends StatelessWidget {
  const MapLocationPickerPage({
    super.key,
    this.onConfirmed,
    this.mapBuilder,
    this.debugIsReleaseModeOverride,
    this.debugApiKeyOverride,
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

  /// Test-only override for release/debug mode. When null, uses real
  /// `kReleaseMode`. Allows deterministic testing of all 4 combinations
  /// without mocking compile-time constants.
  final bool? debugIsReleaseModeOverride;

  /// Test-only override for API key. When null, uses `String.fromEnvironment`.
  final String? debugApiKeyOverride;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MapPickerCubit>(
      create: (_) => sl<MapPickerCubit>()..initialize(),
      child: _MapLocationPickerView(
        onConfirmed: onConfirmed,
        mapBuilder: mapBuilder,
        debugIsReleaseModeOverride: debugIsReleaseModeOverride,
        debugApiKeyOverride: debugApiKeyOverride,
      ),
    );
  }
}

class _MapLocationPickerView extends StatefulWidget {
  const _MapLocationPickerView({
    this.onConfirmed,
    this.mapBuilder,
    this.debugIsReleaseModeOverride,
    this.debugApiKeyOverride,
  });

  final ValueChanged<LocationCoordinates>? onConfirmed;
  final Widget Function(
    BuildContext context,
    LocationCoordinates center,
    ValueChanged<LatLng> onMapMoved,
    bool isDark,
  )? mapBuilder;
  final bool? debugIsReleaseModeOverride;
  final String? debugApiKeyOverride;

  @override
  State<_MapLocationPickerView> createState() => _MapLocationPickerViewState();
}

class _MapLocationPickerViewState extends State<_MapLocationPickerView> {
  final MapController _mapController = MapController();

  // Tile error handling — single debounced map-level state, no SnackBar per tile.
  bool _hasTileError = false;
  bool _tileErrorLogged = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  TileProviderSelection _selectionFor({required bool isDark}) {
    // When debug overrides are provided, use pure resolve() for deterministic
    // testing of all 4 combos (debug/release x with/without key). Otherwise
    // production uses real kReleaseMode + String.fromEnvironment.
    if (widget.debugIsReleaseModeOverride != null ||
        widget.debugApiKeyOverride != null) {
      return TileProviderConfig.resolve(
        isReleaseMode: widget.debugIsReleaseModeOverride ?? false,
        apiKey: widget.debugApiKeyOverride ?? '',
        isDark: isDark,
      );
    }
    return TileProviderConfig.resolveForCurrent(isDark: isDark);
  }

  void _onTileError(dynamic tile, Object error, StackTrace? stackTrace) {
    // Debounce: only first tile error triggers map-level indicator.
    // Do not log the tile URL (contains API key); only coordinates/error type.
    if (_tileErrorLogged) return;
    _tileErrorLogged = true;
    debugPrint('[MapPicker] tile load failed: $error');
    if (mounted) {
      setState(() => _hasTileError = true);
    }
  }

  void _resetTileErrorForThemeChange() {
    // When theme switches, FlutterMap is recreated via ValueKey; reset
    // debounced error so new provider's tiles can be evaluated.
    if (_hasTileError || _tileErrorLogged) {
      _hasTileError = false;
      _tileErrorLogged = false;
    }
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
                      // Map or loading — polished per theme, minimal noise
                      if (state.isLoading)
                        Container(
                          key: const Key('map_picker_loading'),
                          color: isDark
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFFF6F6F3),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: colors.primary,
                            ),
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
                      // Tile error placeholder — single debounced map-level indicator.
                      // Preserves map interaction and attribution visibility.
                      // Does not expose API key, does not claim HTTP status.
                      if (_hasTileError)
                        Positioned(
                          left: AppSpacing.md,
                          right: AppSpacing.md,
                          top: AppSpacing.md + 52, // below recenter
                          child: Container(
                            key: const Key('map_picker_tile_error'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: (isDark
                                      ? const Color(0xFF1A1A1A)
                                      : colors.surface)
                                  .withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colors.border.withValues(alpha: 0.8),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.wifi_off_rounded,
                                  size: 14,
                                  color: colors.mutedText,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    l10n.mapPickerTileError,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: colors.mutedText,
                                          fontSize: 11,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Attribution — RTL-aware, always visible, correct provider
                      // Uses current theme selection; never shows empty in debug
                      // (debug without key falls back to OSM, release without key
                      // shows config error but attribution still readable in map area).
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
                            color: (isDark
                                    ? const Color(0xFF1A1A1A)
                                    : colors.surface)
                                .withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : colors.border.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Builder(
                            builder: (innerContext) {
                              final selection = _selectionFor(isDark: isDark);
                              final attribution = selection
                                      .attribution.isNotEmpty
                                  ? selection.attribution
                                  : (TileProviderConfig
                                          .activeAttribution.isNotEmpty
                                      ? TileProviderConfig.activeAttribution
                                      : l10n.mapPickerAttribution);
                              return Text(
                                attribution,
                                style: Theme.of(innerContext)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                  color: colors.mutedText,
                                  fontSize: 10,
                                ),
                              );
                            },
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
                                      // Typed result for next phase — must match Route<LocationCoordinates?>
                                      Navigator.of(context)
                                          .pop<LocationCoordinates>(coords);
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
    // Release-safe selection: pure logic, testable via isReleaseMode+apiKey.
    // Production uses actual kReleaseMode via resolveForCurrent.
    final selection = _selectionFor(isDark: isDark);

    // Release without key → localized configuration error, never OSM.
    // No exception during widget construction; check isConfigurationError.
    if (selection.isConfigurationError) {
      final l10n = AppLocalizations.of(context).address;
      return Container(
        key: const Key('map_picker_config_error'),
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF6F6F3),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 48,
                  color: colors.mutedText,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.mapPickerConfigErrorTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.headingText,
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.mapPickerConfigErrorBody,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.mutedText,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // When a test injects a fake builder, use it — except config error above.
    if (widget.mapBuilder != null) {
      return widget.mapBuilder!(
        context,
        center,
        (latLng) => context.read<MapPickerCubit>().onMapMoved(latLng),
        isDark,
      );
    }

    // Theme-aware premium tiles: light → osm-bright, dark → dark-matter-dark-grey
    // Debug without key → OSM fallback; with key → Geoapify; release without key
    // already returned above. Caching: flutter_map >=8.2.0 NetworkTileProvider
    // + BuiltInMapCachingProvider (native, 1 GB soft limit, respects
    // Cache-Control/ETag) / browser HTTP cache (web); no prefetch/bulk.
    // See TileProviderConfig.cachingNote.
    final tileUrl = selection.urlTemplate;

    return Stack(
      key: const Key('map_picker_map'),
      children: [
        // Charcoal / light container ensures minimal background even before tiles load
        Positioned.fill(
          child: ColoredBox(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF6F6F3),
          ),
        ),
        FlutterMap(
          key: ValueKey<String>(
              'map_${isDark ? 'dark' : 'light'}_${tileUrl.hashCode}'),
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(center.latitude, center.longitude),
            initialZoom: 14,
            minZoom: 3,
            maxZoom: 18,
            backgroundColor:
                isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF6F6F3),
            onMapEvent: (event) {
              // Only update when movement ends, avoid continuous emissions
              if (event is MapEventMoveEnd) {
                context.read<MapPickerCubit>().onMapMoved(event.camera.center);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              // Android applicationId: com.example.luqma_app (verified
              // android/app/build.gradle.kts namespace/applicationId). iOS
              // bundle is com.example.luqmaApp (ios/Runner.xcodeproj
              // PRODUCT_BUNDLE_IDENTIFIER) — documented difference, tile
              // requests use Android ID for consistency; web ignores this
              // header (browser controls User-Agent).
              userAgentPackageName:
                  TileProviderConfig.userAgentPackageName,
              maxZoom: 20,
              // Caching: default NetworkTileProvider is used (no explicit
              // tileProvider:) so BuiltInMapCachingProvider is auto-enabled
              // on native (1 GB soft limit, respects HTTP headers). Do NOT set
              // overrideFreshAge or custom maxCacheSize — respect provider
              // headers; OSM 7-day fallback applies only to tile.openstreetmap.org,
              // Geoapify respects its own headers. No prefetch/bulk/offline.
              errorImage: null,
              tileBuilder: (context, tileWidget, tile) {
                // Themed placeholder for failed tiles: tile object does not
                // expose HTTP status (401/403/429), so we do not claim to
                // distinguish it. Preserve map interaction; attribution stays
                // visible via overlay. The per-tile placeholder is neutral
                // (charcoal/light + icon) and complements the single
                // debounced map-level banner in the parent Stack.
                try {
                  final dynamic t = tile;
                  // flutter_map's TileImage may expose loadError/error;
                  // check both without breaking if field missing.
                  final hasError = (t.loadError != null) ||
                      (t.error != null) ||
                      (t is Widget && false);
                  if (hasError) {
                    return Container(
                      color: isDark
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFFF6F6F3),
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 16,
                          color: colors.mutedText.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  }
                } catch (_) {
                  // If API differs, fall back to normal tileWidget.
                }
                return tileWidget;
              },
              errorTileCallback: _onTileError,
            ),
          ],
        ),
        // Fixed centre pin — Burgundy from theme token
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
    // Phase E: Burgundy background with contrasting icon (Luqma primary token)
    return Material(
      color: Colors.transparent,
      elevation: 3,
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
            color: colors.primary, // Burgundy #7B1E28 via theme token
            border: Border.all(color: colors.primary.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: isLocating
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.onPrimary,
                    ),
                  )
                : Icon(
                    Icons.my_location_rounded,
                    color: colors.onPrimary, // white / F6F1E7 contrast
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
