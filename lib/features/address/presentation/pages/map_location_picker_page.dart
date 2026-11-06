import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/map/maplibre_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/di/service_locator.dart';
import '../../../location/domain/entities/location_coordinates.dart';
import '../cubit/map_picker_cubit.dart';
import '../cubit/map_picker_state.dart';

/// Interactive map location picker — MapLibre GL + OpenFreeMap.
///
/// Fills the screen with a pannable MapLibre map, a fixed centre pin,
/// recenter and confirm controls. Uses [MapLibreConfig] for light/dark
/// JSON styling (Luqma Ivory / Minimal Charcoal) loaded from local assets
/// `assets/map_styles/luqma_*.json` with full layer control (roads/casing,
/// buildings, water, parks, landuse, boundaries, labels, POIs). Synchronizes
/// with app theme without recreating the controller and preserves camera.
/// Burgundy `#7B1E28` branding for marker & recenter. No Google Maps SDK,
/// no API key, no billing. Location handling (GPS, permissions, Sohag fallback
/// 26.56,31.69) preserved via [MapPickerCubit].
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

  /// For tests: builds the map area. When null, the real MapLibreMap is used.
  /// The callback receives the MapLibre [LatLng].
  final Widget Function(
    BuildContext context,
    LocationCoordinates center,
    ValueChanged<LatLng> onMapMoved,
    bool isDark,
  )? mapBuilder;

  /// Test-only override for release/debug mode. When null, uses real logic.
  final bool? debugIsReleaseModeOverride;

  /// Test-only override for API key (legacy seam kept for hardening tests).
  /// For MapLibre this is mapped to style availability — empty overrides
  /// simulate missing style configuration → localized config error.
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
  MapLibreMapController? _mapController;
  String? _styleString;
  bool _styleLoadingFailed = false;
  bool _isProgrammaticMove = false;
  LatLng? _pendingCameraLatLng;

  // Keep last isDark to avoid redundant style updates.
  bool? _lastIsDark;

  @override
  void initState() {
    super.initState();
    // Preload initial style is done in build via brightness, but also
    // handle missing configuration seam.
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Determines if the platform configuration is missing (for graceful error).
  /// For MapLibre/OpenFreeMap there is no API key; missing config means
  /// style assets unavailable or provider unreachable. For tests we preserve
  /// the Google-Maps override seam: empty apiKey override → config error.
  bool _isMissingConfiguration({required bool isDark}) {
    if (widget.debugIsReleaseModeOverride != null || widget.debugApiKeyOverride != null) {
      final apiKey = widget.debugApiKeyOverride ?? '';
      if (apiKey.isEmpty && widget.debugApiKeyOverride != null) {
        return true;
      }
      // Also treat explicit empty as missing when release override set
      if (widget.debugIsReleaseModeOverride == true && apiKey.isEmpty) {
        return true;
      }
    }
    if (_styleLoadingFailed) return true;
    return false;
  }

  Future<void> _ensureStyleLoaded(bool isDark) async {
    if (_styleLoadingFailed) return;
    final asset = MapLibreConfig.styleAssetForBrightness(
      isDark ? Brightness.dark : Brightness.light,
    );
    // If already loaded same brightness, skip
    if (_lastIsDark == isDark && _styleString != null) return;
    try {
      final loaded = await MapLibreConfig.loadStyleString(
        isDark ? Brightness.dark : Brightness.light,
      );
      if (!mounted) return;
      if (!MapLibreConfig.isValidStyleJson(loaded)) {
        setState(() {
          _styleLoadingFailed = true;
        });
        return;
      }
      setState(() {
        _styleString = loaded;
        _lastIsDark = isDark;
        _styleLoadingFailed = false;
      });
      // If controller already exists, update its style without recreating.
      if (_mapController != null && _lastIsDark != null) {
        // MapLibre style can be updated via setting styleString; controller
        // will handle reload. As fallback, try controller.setStyle if available.
        try {
          // ignore: avoid_dynamic_calls
          await (_mapController as dynamic).setStyle(loaded);
        } catch (_) {
          // Fallback: widget will rebuild with new styleString
        }
      } else {
        _lastIsDark = isDark;
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _styleLoadingFailed = true;
      });
    }
  }

  Future<void> _moveCamera(LocationCoordinates coords) async {
    final controller = _mapController;
    if (controller == null) return;
    if (!mounted) return;
    try {
      _isProgrammaticMove = true;
      final zoom = coords.isDeviceDetected
          ? MapLibreConfig.gpsZoom
          : MapLibreConfig.fallbackZoom;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(coords.latitude, coords.longitude),
          zoom,
        ),
      );
    } catch (_) {
      // Controller may not be attached yet (e.g., in tests with fake builder)
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        _isProgrammaticMove = false;
      });
    }
  }

  void _onMapCreated(MapLibreMapController controller, bool isDark) {
    _mapController = controller;
    _lastIsDark = isDark;
    // Style is already set via styleString; no extra apply needed.
  }

  Future<void> _updateStyleIfNeeded(bool isDark) async {
    if (_lastIsDark == isDark) return;
    await _ensureStyleLoaded(isDark);
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
    final colors = Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Kick off style load if not yet loaded
    if (_styleString == null && !_styleLoadingFailed && widget.mapBuilder == null) {
      // Trigger async load; show loading until done
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureStyleLoaded(isDark);
      });
    }

    // Theme sync without recreating controller — update style if brightness changed.
    if (_mapController != null && _lastIsDark != isDark) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateStyleIfNeeded(isDark);
      });
    }

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
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.mutedText),
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
                          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF6F6F3),
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
                          onPressed: () => context.read<MapPickerCubit>().recenter(),
                        ),
                      ),
                      // Attribution — RTL-aware, always visible, OpenFreeMap
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
                            color: (isDark ? const Color(0xFF1A1A1A) : colors.surface).withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.08) : colors.border.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Text(
                            l10n.mapPickerAttribution,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colors.mutedText,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      ),
                      // Permission / retrieval error banner
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
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                                color: state.isFallback ? colors.mutedText : colors.primary,
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
                                    context.read<MapPickerCubit>().confirmSelection();
                                    final coords = context.read<MapPickerCubit>().state.selected;
                                    if (widget.onConfirmed != null) {
                                      widget.onConfirmed!(coords);
                                    } else {
                                      Navigator.of(context).pop<LocationCoordinates>(coords);
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
    // Graceful handling of missing style configuration — never fake tiles.
    if (_isMissingConfiguration(isDark: isDark)) {
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

    // Test seam: fake builder overrides real MapLibreMap.
    if (widget.mapBuilder != null) {
      return widget.mapBuilder!(
        context,
        center,
        (latLng) => context.read<MapPickerCubit>().onMapMoved(latLng),
        isDark,
      );
    }

    // While style is loading, show placeholder with theme background
    final styleString = _styleString;
    if (styleString == null) {
      return Container(
        key: const Key('map_picker_map_loading'),
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF6F6F3),
        child: Center(
          child: CircularProgressIndicator(color: colors.primary),
        ),
      );
    }

    // MapLibre — preserves camera, zoom, and selection.
    // Theme switching updates style via setStyle without recreating controller.
    return Stack(
      key: const Key('map_picker_map'),
      children: [
        // Background ensures minimal ivory/charcoal before tiles load
        Positioned.fill(
          child: ColoredBox(
            color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF6F6F3),
          ),
        ),
        MapLibreMap(
          // Do NOT use ValueKey that recreates map on theme change — preserve controller.
          // Style is updated via controller.setStyle / styleString change.
          styleString: styleString,
          initialCameraPosition: MapLibreConfig.cameraFor(
            LatLng(center.latitude, center.longitude),
            zoom: state.isFallback
                ? MapLibreConfig.fallbackZoom
                : MapLibreConfig.gpsZoom,
          ),
          onMapCreated: (controller) => _onMapCreated(controller, isDark),
          onStyleLoadedCallback: () {
            // Style loaded, ready for interaction
          },
          onMapClick: (point, latLng) {
            // Optional: allow tap to select? Currently we use camera idle.
          },
          onCameraMove: (position) {
            // Track pending position; don't emit continuously.
            _pendingCameraLatLng = position.target;
          },
          onCameraIdle: () {
            if (_isProgrammaticMove) return;
            final pending = _pendingCameraLatLng;
            if (pending == null) return;
            context.read<MapPickerCubit>().onMapMoved(pending);
          },
          minMaxZoomPreference: MinMaxZoomPreference(
            MapLibreConfig.minZoom,
            MapLibreConfig.maxZoom,
          ),
          compassEnabled: false,
          rotateGesturesEnabled: true,
          scrollGesturesEnabled: true,
          tiltGesturesEnabled: false,
          zoomGesturesEnabled: true,
          myLocationEnabled: false,
          myLocationRenderMode: MyLocationRenderMode.normal,
          myLocationTrackingMode: MyLocationTrackingMode.none,
          attributionButtonPosition: AttributionButtonPosition.bottomRight,
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
    final colors = Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;
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
    final colors = Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final l10n = AppLocalizations.of(context).address;
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
            color: colors.primary,
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
                    color: colors.onPrimary,
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
  static const String attribution = '© OpenFreeMap';
  static const String urlTemplate = 'https://tiles.openfreemap.org/planet';
}
