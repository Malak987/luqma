import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/queries/catalog_identifiers.dart';
import '../../domain/repositories/store_details_repository.dart';
import '../models/catalog_response_envelope_model.dart';
import '../models/store_model.dart';

/// In-memory, bounded, per-store and per-origin snapshots. In-flight requests
/// for the same key are shared; errors never overwrite a confirmed snapshot.
class StoreDetailsRepositoryImpl implements StoreDetailsRepository {
  StoreDetailsRepositoryImpl(this._client,
      {this.ttl = const Duration(minutes: 3), DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;
  final DioClient _client;
  final Duration ttl;
  final DateTime Function() _clock;
  final Map<String, StoreDetailsSnapshot> _cache = {};
  final Map<String, Future<StoreDetailsSnapshot>> _inFlight = {};

  String _key(String id, StoreDetailsLocation? location) =>
      '${id.toLowerCase()}|${location?.latitude}|${location?.longitude}';

  @override
  StoreDetailsSnapshot? cached(String id, StoreDetailsLocation? location) =>
      _cache[_key(id, location)];

  @override
  Future<StoreDetailsSnapshot> get(String id,
      {StoreDetailsLocation? location, bool force = false}) {
    if (!isCatalogId(id) || (location != null && !location.isValid)) {
      return Future.error(
          const FailureException(Failure(FailureCode.validation)));
    }
    final key = _key(id, location);
    final previous = _cache[key];
    final age =
        previous == null ? null : _clock().difference(previous.fetchedAt);
    if (!force &&
        previous != null &&
        age != null &&
        !age.isNegative &&
        age < ttl) {
      return Future.value(previous);
    }
    final running = _inFlight[key];
    if (running != null) return running;
    final future = _fetch(id, location).then((snapshot) {
      _cache.remove(key);
      _cache[key] = snapshot;
      if (_cache.length > 50) _cache.remove(_cache.keys.first);
      return snapshot;
    });
    _inFlight[key] = future;
    future.then<void>((_) => _inFlight.remove(key),
        onError: (Object _, StackTrace __) {
      _inFlight.remove(key);
    });
    return future;
  }

  Future<StoreDetailsSnapshot> _fetch(
      String id, StoreDetailsLocation? location) async {
    try {
      final response = await _client.dio.get<Object?>(
        '/api/Store/GetById/$id',
        queryParameters: location == null
            ? null
            : {'latitude': location.latitude, 'longitude': location.longitude},
      );
      final store = StoreModel.fromJson(
              CatalogResponseEnvelopeModel.fromJson(response.data)
                  .requireSuccess())
          .toDomain();
      if (store.id.toLowerCase() != id.toLowerCase()) {
        throw const FailureException(Failure(FailureCode.unknown));
      }
      return StoreDetailsSnapshot(store, _clock());
    } on FailureException {
      rethrow;
    } on RemoteException catch (e) {
      throw FailureException(Failure(e.code));
    } on DioException catch (e) {
      final isNetwork = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.badCertificate;
      throw FailureException(
          Failure(isNetwork ? FailureCode.network : FailureCode.unknown));
    } catch (_) {
      throw const FailureException(Failure(FailureCode.unknown));
    }
  }
}
