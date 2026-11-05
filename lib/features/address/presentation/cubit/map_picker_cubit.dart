import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../location/domain/entities/current_location_outcome.dart';
import '../../../location/domain/entities/location_coordinates.dart';
import '../../../location/domain/usecases/get_current_location_use_case.dart';
import '../../../location/domain/usecases/request_location_permission_use_case.dart';
import 'map_picker_state.dart';

/// Controls the map location picker.
/// Reuses existing location use-cases; no direct Geolocator/Repository access.
class MapPickerCubit extends Cubit<MapPickerState> {
  MapPickerCubit({
    required GetCurrentLocationUseCase getCurrentLocationUseCase,
    required RequestLocationPermissionUseCase requestLocationPermissionUseCase,
  })  : _getCurrentLocationUseCase = getCurrentLocationUseCase,
        _requestLocationPermissionUseCase = requestLocationPermissionUseCase,
        super(const MapPickerState());

  final GetCurrentLocationUseCase _getCurrentLocationUseCase;
  final RequestLocationPermissionUseCase _requestLocationPermissionUseCase;

  bool _isInitializing = false;
  bool _isLocating = false;

  /// Initial load: tries GPS, falls back to Sohag.
  /// Expected permission/service outcomes (Denied, PermanentlyDenied,
  /// ServiceDisabled, RequestRequired) use fallback without an error banner.
  /// Only actual [LocationRetrievalFailure] shows a localized error; fallback
  /// is never labelled as device location. Manual map selection when permission
  /// is denied is preserved via [onMapMoved].
  Future<void> initialize() async {
    if (_isInitializing || isClosed) return;
    _isInitializing = true;
    emit(state.copyWith(
      status: MapPickerStatus.loading,
      clearError: true,
    ));

    try {
      final outcome = await _getCurrentLocationUseCase();
      if (isClosed) return;

      if (outcome is CurrentLocationSuccess) {
        emit(MapPickerState(
          selected: outcome.coordinates,
          status: MapPickerStatus.ready,
          isFallback: false,
        ));
      } else if (outcome is LocationRetrievalFailure) {
        // Actual failure — show error in addition to fallback.
        emit(MapPickerState(
          selected: LocationCoordinates.sohagMapStartFallback,
          status: MapPickerStatus.ready,
          isFallback: true,
          errorMessage: _outcomeToMessage(outcome),
        ));
      } else {
        // Expected permission/service outcomes — fallback without banner.
        emit(MapPickerState(
          selected: LocationCoordinates.sohagMapStartFallback,
          status: MapPickerStatus.ready,
          isFallback: true,
        ));
      }
    } finally {
      _isInitializing = false;
    }
  }

  /// Called when map movement ends (not during continuous pan).
  /// Updates selected coordinates as a manual map selection.
  /// Deduplicates with epsilon 1e-6° (≈0.11 m at equator; 0.0000004°≈4.4 cm).
  /// Identical or tiny movements below threshold are ignored to avoid
  /// unnecessary emissions; legitimate moves above threshold emit.
  void onMapMoved(LatLng center) {
    if (isClosed) return;
    const double epsilon = 0.000001; // ~11 cm, avoids 44 m miscalc
    if ((state.selected.latitude - center.latitude).abs() < epsilon &&
        (state.selected.longitude - center.longitude).abs() < epsilon) {
      return;
    }
    final newCoords = LocationCoordinates.fromMapSelection(
      latitude: center.latitude,
      longitude: center.longitude,
    );
    emit(state.copyWith(
      selected: newCoords,
      status: MapPickerStatus.ready,
      isFallback: false,
      clearError: true,
    ));
  }

  /// Recenter button: tries GPS again, handles permission/service errors.
  /// Uses explicit permission request to avoid consuming automatic budget.
  /// Preserves permission-attempt limits (explicit does not consume automatic
  /// budget) and keeps current selection on failure.
  Future<void> recenter() async {
    if (_isLocating || isClosed) return;
    if (state.isLoading) return;
    _isLocating = true;
    emit(state.copyWith(
      status: MapPickerStatus.locating,
      clearError: true,
    ));

    try {
      // First try normal getCurrentLocation (respects automatic policy, no prompt)
      final first = await _getCurrentLocationUseCase();
      if (isClosed) return;

      if (first is CurrentLocationSuccess) {
        emit(MapPickerState(
          selected: first.coordinates,
          status: MapPickerStatus.ready,
          isFallback: false,
        ));
        return;
      }

      // If permission request is required or denied, try explicit request (user-initiated)
      if (first is LocationPermissionRequestRequired ||
          first is LocationPermissionDenied ||
          first is LocationPermanentlyDenied) {
        final second = await _requestLocationPermissionUseCase(
          mode: LocationPermissionRequestMode.explicit,
        );
        if (isClosed) return;
        if (second is CurrentLocationSuccess) {
          emit(MapPickerState(
            selected: second.coordinates,
            status: MapPickerStatus.ready,
            isFallback: false,
          ));
          return;
        }
        // Still failed — keep current selection, show error, stay on current fallback/manual
        emit(state.copyWith(
          status: MapPickerStatus.ready,
          errorMessage: _outcomeToMessage(second),
        ));
        return;
      }

      // Service disabled, retrieval failure, etc. — keep selection, show error
      emit(state.copyWith(
        status: MapPickerStatus.ready,
        errorMessage: _outcomeToMessage(first),
      ));
    } finally {
      _isLocating = false;
    }
  }

  /// Confirm selection: returns typed result via state for next phase.
  /// The UI should read state.confirmed or state.selected after this.
  void confirmSelection() {
    if (isClosed) return;
    if (state.isLoading || state.isLocating) return;
    emit(state.copyWith(
      status: MapPickerStatus.confirmed,
      confirmed: state.selected,
      clearError: true,
    ));
  }

  String? _outcomeToMessage(CurrentLocationOutcome outcome) {
    // These messages are not localized here; UI localizes via l10n.
    // We keep a short English key for tests, UI maps to localized copy.
    if (outcome is LocationServiceDisabled) return 'service_disabled';
    if (outcome is LocationPermissionDenied) return 'permission_denied';
    if (outcome is LocationPermanentlyDenied) return 'permission_permanently_denied';
    if (outcome is LocationPermissionRequestRequired) return 'permission_required';
    if (outcome is LocationRetrievalFailure) return 'retrieval_failed:${outcome.reason}';
    if (outcome is CurrentLocationSuccess) return null;
    return 'unknown';
  }
}
