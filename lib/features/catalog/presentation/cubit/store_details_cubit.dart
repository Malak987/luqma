import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/store.dart';
import '../../domain/repositories/store_details_repository.dart';
import '../../domain/usecases/get_store_details_use_case.dart';

class StoreDetailsState {
  const StoreDetailsState(
      {required this.store,
      this.loading = false,
      this.stale = true,
      this.failed = false});
  final Store store;
  final bool loading, stale, failed;
}

class StoreDetailsCubit extends Cubit<StoreDetailsState> {
  StoreDetailsCubit(
      {required Store initial,
      required GetStoreDetailsUseCase getDetails,
      StoreDetailsLocation? location})
      : _location = location,
        _getDetails = getDetails,
        super(StoreDetailsState(store: initial));
  final GetStoreDetailsUseCase _getDetails;
  StoreDetailsLocation? _location;
  StoreDetailsLocation? get location => _location;

  Future<void> changeLocation(StoreDetailsLocation? location) async {
    final valid = location?.isValid == true ? location : null;
    if (_location?.latitude == valid?.latitude &&
        _location?.longitude == valid?.longitude) return;
    _location = valid;
    await load();
  }

  int _generation = 0;
  Future<void> changeStore(Store store) async {
    if (isClosed || store.id.toLowerCase() == state.store.id.toLowerCase())
      return;
    _generation++;
    emit(StoreDetailsState(store: store));
    await load();
  }

  Future<void> load({bool force = false}) async {
    final generation = ++_generation;
    final id = state.store.id;
    final old = _getDetails.cached(id, location);
    emit(StoreDetailsState(store: old?.store ?? state.store, loading: true));
    try {
      final result = await _getDetails(id, location: location, force: force);
      if (!isClosed && generation == _generation)
        emit(StoreDetailsState(store: result.store, stale: false));
    } catch (_) {
      if (!isClosed && generation == _generation)
        emit(StoreDetailsState(store: old?.store ?? state.store, failed: true));
    }
  }
}
