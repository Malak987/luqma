import 'package:equatable/equatable.dart';

import '../../../location/domain/entities/location_coordinates.dart';

enum MapPickerStatus {
  initial,
  loading,
  ready,
  locating,
  error,
  confirmed,
}

class MapPickerState extends Equatable {
  const MapPickerState({
    this.selected = LocationCoordinates.sohagMapStartFallback,
    this.status = MapPickerStatus.initial,
    this.isFallback = true,
    this.errorMessage,
    this.confirmed,
  });

  /// Currently selected coordinates — centre of the map pin.
  final LocationCoordinates selected;

  /// High-level status for UI (loading, ready, locating, etc.).
  final MapPickerStatus status;

  /// True when [selected] is the Sohag fallback, i.e. not a GPS fix and not
  /// yet a manual map selection that the user explicitly chose.
  /// Used to show the subtle fallback indicator. Never label fallback as
  /// "current location".
  final bool isFallback;

  /// Optional error message for permission/service failures (localized).
  final String? errorMessage;

  /// When the user confirms, this holds the final coordinates to pass forward.
  /// The coordinates themselves are in [selected]; this is a convenience copy
  /// set only on confirmation.
  final LocationCoordinates? confirmed;

  bool get isInitialized => status != MapPickerStatus.initial;
  bool get isLoading => status == MapPickerStatus.loading;
  bool get isLocating => status == MapPickerStatus.locating;
  bool get isReady => status == MapPickerStatus.ready;
  bool get isConfirmed => status == MapPickerStatus.confirmed;

  MapPickerState copyWith({
    LocationCoordinates? selected,
    MapPickerStatus? status,
    bool? isFallback,
    String? errorMessage,
    LocationCoordinates? confirmed,
    bool clearError = false,
    bool clearConfirmed = false,
  }) {
    return MapPickerState(
      selected: selected ?? this.selected,
      status: status ?? this.status,
      isFallback: isFallback ?? this.isFallback,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      confirmed: clearConfirmed ? null : (confirmed ?? this.confirmed),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        selected,
        status,
        isFallback,
        errorMessage,
        confirmed,
      ];
}
