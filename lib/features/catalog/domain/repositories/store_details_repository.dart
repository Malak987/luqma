import '../entities/store.dart';

class StoreDetailsLocation {
  const StoreDetailsLocation(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

class StoreDetailsSnapshot {
  const StoreDetailsSnapshot(this.store, this.fetchedAt);
  final Store store;
  final DateTime fetchedAt;
}

abstract interface class StoreDetailsRepository {
  StoreDetailsSnapshot? cached(String id, StoreDetailsLocation? location);
  Future<StoreDetailsSnapshot> get(String id,
      {StoreDetailsLocation? location, bool force = false});
}
