import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/features/home/domain/entities/home_category.dart';
import 'package:luqma_app/features/home/domain/usecases/get_all_main_categories_use_case.dart';
import 'package:luqma_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:luqma_app/features/home/presentation/cubit/home_state.dart';

import '../../support/main_category_fixtures.dart';

void main() {
  group('HomeCubit', () {
    late _FakeSecureStorageService storage;
    late FakeMainCategoryRepository repository;
    late HomeCubit cubit;

    setUp(() {
      storage = _FakeSecureStorageService(userName: '  Malak  ');
      repository = FakeMainCategoryRepository();
      cubit = HomeCubit(
        secureStorageService: storage,
        getAllMainCategoriesUseCase: GetAllMainCategoriesUseCase(repository),
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('starts with initial profile and category states', () {
      expect(cubit.state.status, HomeStatus.initial);
      expect(cubit.state.categoriesStatus, HomeCategoriesStatus.initial);
      expect(cubit.state.userName, isNull);
      expect(cubit.state.categories, isEmpty);
      expect(cubit.state.restaurants, isEmpty);
      expect(cubit.state.hasFailure, isFalse);
      expect(cubit.state.categoriesFailure, isNull);
    });

    test('loads the persisted display name alongside the catalog', () async {
      final states = <HomeState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);

      await cubit.load();
      await pumpEventQueue();

      expect(states.first.status, HomeStatus.loading);
      expect(cubit.state.status, HomeStatus.loaded);
      expect(cubit.state.userName, 'Malak');
      expect(cubit.state.categoriesStatus, HomeCategoriesStatus.empty);
      expect(cubit.state.restaurants, isEmpty);
      expect(repository.calls, 1);
      expect(storage.reads, 1);
    });

    test('treats a blank profile name as no name', () async {
      storage.userName = '   ';
      await cubit.load();
      expect(cubit.state.userName, isNull);
      expect(cubit.state.status, HomeStatus.loaded);
    });

    test('emits loading then success with filtered, sorted API categories',
        () async {
      final first = homeCategory(id: 'first', displayOrder: 1);
      final second = homeCategory(id: 'second', displayOrder: 2);
      repository.categories = <HomeCategory>[
        second,
        homeCategory(id: 'hidden', displayOrder: 0, isActive: false),
        first,
      ];
      final states = <HomeState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);

      await cubit.loadCategories();
      await pumpEventQueue();

      expect(
          states.map((state) => state.categoriesStatus), <HomeCategoriesStatus>[
        HomeCategoriesStatus.loading,
        HomeCategoriesStatus.success,
      ]);
      expect(cubit.state.categories, <HomeCategory>[first, second]);
      expect(cubit.state.categoriesFailure, isNull);
    });

    test('emits loading then empty for an empty successful response', () async {
      final states = <HomeState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);

      await cubit.loadCategories();
      await pumpEventQueue();

      expect(
          states.map((state) => state.categoriesStatus), <HomeCategoriesStatus>[
        HomeCategoriesStatus.loading,
        HomeCategoriesStatus.empty,
      ]);
      expect(cubit.state.categories, isEmpty);
      expect(cubit.state.categoriesFailure, isNull);
    });

    test('all-inactive results produce the explicit empty state', () async {
      repository.categories = <HomeCategory>[homeCategory(isActive: false)];
      await cubit.loadCategories();
      expect(cubit.state.categoriesStatus, HomeCategoriesStatus.empty);
      expect(cubit.state.categories, isEmpty);
    });

    test('emits loading then error without turning a failure into empty',
        () async {
      const failure = Failure(FailureCode.network, debugMessage: 'offline');
      repository.exception = const FailureException(failure);
      final states = <HomeState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);

      await cubit.loadCategories();
      await pumpEventQueue();

      expect(
          states.map((state) => state.categoriesStatus), <HomeCategoriesStatus>[
        HomeCategoriesStatus.loading,
        HomeCategoriesStatus.error,
      ]);
      expect(cubit.state.categoriesFailure, failure);
    });

    test('keeps Home loaded when the category API fails', () async {
      repository.exception =
          const FailureException(Failure(FailureCode.network));
      await cubit.load();

      expect(cubit.state.status, HomeStatus.loaded);
      expect(cubit.state.userName, 'Malak');
      expect(cubit.state.hasFailure, isFalse);
      expect(cubit.state.categoriesStatus, HomeCategoriesStatus.error);
    });

    test('does not block the rest of Home on a pending category request',
        () async {
      repository.pendingResult = Completer<List<HomeCategory>>();
      final load = cubit.load();
      await pumpEventQueue();

      expect(cubit.state.status, HomeStatus.loaded);
      expect(cubit.state.userName, 'Malak');
      expect(cubit.state.categoriesStatus, HomeCategoriesStatus.loading);

      repository.pendingResult!.complete(<HomeCategory>[homeCategory()]);
      await load;
      expect(cubit.state.categoriesStatus, HomeCategoriesStatus.success);
    });

    test('maps unexpected category failures to unknown', () async {
      repository.exception = StateError('Injected failure');
      await cubit.loadCategories();

      expect(cubit.state.categoriesStatus, HomeCategoriesStatus.error);
      expect(cubit.state.categoriesFailure?.code, FailureCode.unknown);
    });

    test('retries only the catalog and clears its previous failure', () async {
      repository.exception =
          const FailureException(Failure(FailureCode.network));
      await cubit.load();
      expect(cubit.state.categoriesStatus, HomeCategoriesStatus.error);

      repository.exception = null;
      repository.categories = <HomeCategory>[homeCategory()];
      final retry = cubit.retryCategories();
      expect(cubit.state.categoriesStatus, HomeCategoriesStatus.loading);
      expect(cubit.state.categoriesFailure, isNull);
      expect(cubit.state.userName, 'Malak');
      await retry;

      expect(cubit.state.categoriesStatus, HomeCategoriesStatus.success);
      expect(cubit.state.status, HomeStatus.loaded);
      expect(repository.calls, 2);
      expect(storage.reads, 1);
    });

    test('ignores duplicate loads and retries while requests are in flight',
        () async {
      storage.pendingName = Completer<String?>();
      repository.pendingResult = Completer<List<HomeCategory>>();

      final first = cubit.load();
      await cubit.load();
      await cubit.loadCategories();
      await cubit.retryCategories();

      expect(storage.reads, 1);
      expect(repository.calls, 1);
      storage.pendingName!.complete('Malak');
      repository.pendingResult!.complete(<HomeCategory>[]);
      await first;
      expect(cubit.state.status, HomeStatus.loaded);
      expect(cubit.state.categoriesStatus, HomeCategoriesStatus.empty);
    });

    for (final populated in <bool>[false, true]) {
      test(
          'reuses ${populated ? 'successful' : 'empty'} results for this visit',
          () async {
        repository.categories =
            populated ? <HomeCategory>[homeCategory()] : <HomeCategory>[];
        await cubit.load();
        await cubit.load();
        await cubit.loadCategories();

        expect(repository.calls, 1);
        expect(storage.reads, 1);
      });
    }

    test('preserves a profile failure when categories finish later', () async {
      storage.failRead = true;
      repository.pendingResult = Completer<List<HomeCategory>>();
      final load = cubit.load();
      await pumpEventQueue();
      expect(cubit.state.status, HomeStatus.failure);

      repository.pendingResult!.complete(<HomeCategory>[homeCategory()]);
      await load;
      expect(cubit.state.status, HomeStatus.failure);
      expect(cubit.state.failure?.code, FailureCode.unknown);
      expect(cubit.state.categoriesStatus, HomeCategoriesStatus.success);
    });

    test('retries a profile failure without fetching categories again',
        () async {
      storage.failRead = true;
      await cubit.load();
      expect(cubit.state.status, HomeStatus.failure);
      expect(cubit.state.failure?.code, FailureCode.unknown);

      storage.failRead = false;
      await cubit.load();
      expect(cubit.state.status, HomeStatus.loaded);
      expect(cubit.state.failure, isNull);
      expect(cubit.state.userName, 'Malak');
      expect(repository.calls, 1);
    });

    test('does not start work after close', () async {
      await cubit.close();
      await cubit.load();
      await cubit.loadCategories();
      await cubit.retryCategories();
      expect(repository.calls, 0);
      expect(storage.reads, 0);
    });

    for (final fails in <bool>[false, true]) {
      test('ignores ${fails ? 'failure' : 'success'} arriving after close',
          () async {
        repository.pendingResult = Completer<List<HomeCategory>>();
        final load = cubit.loadCategories();
        await cubit.close();
        if (fails) {
          repository.pendingResult!.completeError(
            const FailureException(Failure(FailureCode.network)),
          );
        } else {
          repository.pendingResult!.complete(<HomeCategory>[homeCategory()]);
        }
        await load;
      });
    }
  });

  group('HomeState', () {
    test('category status and failures participate in equality', () {
      const initial = HomeState.initial();
      expect(initial, const HomeState.initial());
      expect(
          initial,
          isNot(initial.copyWith(
              categoriesStatus: HomeCategoriesStatus.loading)));
      expect(
          initial,
          isNot(initial.copyWith(
              categoriesFailure: const Failure(FailureCode.network))));
    });

    test('partial updates preserve independent failures and can clear them',
        () {
      const state = HomeState(
        status: HomeStatus.failure,
        failure: Failure(FailureCode.unknown),
        categoriesStatus: HomeCategoriesStatus.error,
        categoriesFailure: Failure(FailureCode.network),
      );
      final updated =
          state.copyWith(categoriesStatus: HomeCategoriesStatus.loading);
      expect(updated.failure, state.failure);
      expect(updated.categoriesFailure, state.categoriesFailure);
      expect(updated.copyWith(clearFailure: true).failure, isNull);
      expect(updated.copyWith(clearCategoriesFailure: true).categoriesFailure,
          isNull);
    });
  });
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService({this.userName})
      : super(const FlutterSecureStorage());

  String? userName;
  bool failRead = false;
  int reads = 0;
  Completer<String?>? pendingName;

  @override
  Future<String?> getUserName() async {
    reads++;
    if (failRead) throw StateError('Injected storage failure');
    return pendingName == null ? userName : await pendingName!.future;
  }
}
