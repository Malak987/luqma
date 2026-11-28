import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/catalog/domain/entities/store.dart';
import 'package:luqma_app/features/catalog/domain/repositories/store_details_repository.dart';
import 'package:luqma_app/features/catalog/domain/usecases/get_store_details_use_case.dart';
import 'package:luqma_app/features/catalog/presentation/cubit/store_details_cubit.dart';
import '../../support/catalog_fixtures.dart';

class ControlledRepository implements StoreDetailsRepository {
  final calls = <StoreDetailsLocation?>[];
  final pending = <Completer<StoreDetailsSnapshot>>[];
  @override
  StoreDetailsSnapshot? cached(String id, StoreDetailsLocation? location) =>
      null;
  @override
  Future<StoreDetailsSnapshot> get(String id,
      {StoreDetailsLocation? location, bool force = false}) {
    calls.add(location);
    final c = Completer<StoreDetailsSnapshot>();
    pending.add(c);
    return c.future;
  }
}

StoreDetailsSnapshot snap(Store s) =>
    StoreDetailsSnapshot(s, DateTime.utc(2026));
void main() {
  test(
      'changed location ignores late older response, unchanged location is not requested and failure preserves latest store',
      () async {
    final repo = ControlledRepository();
    final c = StoreDetailsCubit(
        initial: store(nameEn: 'Initial'),
        getDetails: GetStoreDetailsUseCase(repo));
    final first = c.load();
    const one = StoreDetailsLocation(26, 31);
    const two = StoreDetailsLocation(27, 32);
    final a = c.changeLocation(one);
    final b = c.changeLocation(two);
    expect(repo.calls.length, 3);
    repo.pending[2].complete(snap(store(nameEn: 'Newest', distanceKm: 5)));
    await b;
    repo.pending[1]
        .complete(snap(store(nameEn: 'Old location', distanceKm: 100)));
    await a;
    repo.pending[0].complete(snap(store(nameEn: 'Older')));
    await first;
    expect(c.state.store.nameEn, 'Newest');
    expect(c.state.store.distanceKm, 5);
    await c.changeLocation(two);
    expect(repo.calls.length, 3);
    final failed = c.changeLocation(const StoreDetailsLocation(28, 33));
    repo.pending[3]
        .completeError(const FailureException(Failure(FailureCode.network)));
    await failed;
    expect(c.state.store.nameEn, 'Newest');
    expect(c.state.failed, isTrue);
    expect(c.state.stale, isTrue);
    await c.close();
  });
}
