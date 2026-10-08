import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:luqma_app/features/home/presentation/cubit/home_state.dart';

void main() {
  group('HomeCubit', () {
    test('starts in the initial state', () {
      final cubit = HomeCubit(
        secureStorageService: _FakeSecureStorageService(),
      );
      addTearDown(cubit.close);

      expect(cubit.state.status, HomeStatus.initial);
      expect(cubit.state.userName, isNull);
      expect(cubit.state.categories, isEmpty);
      expect(cubit.state.restaurants, isEmpty);
      expect(cubit.state.hasFailure, isFalse);
    });

    test('emits loading then loaded with the persisted display name', () async {
      final cubit = HomeCubit(
        secureStorageService: _FakeSecureStorageService(userName: '  Malak  '),
      );
      addTearDown(cubit.close);

      final states = <HomeState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);

      await cubit.load();
      // The cubit's stream delivers states asynchronously.
      await pumpEventQueue();

      expect(
        states.map((state) => state.status),
        <HomeStatus>[HomeStatus.loading, HomeStatus.loaded],
      );
      expect(cubit.state.userName, 'Malak');
      // The home content endpoints do not exist yet, so the sections stay empty
      // instead of rendering sample data.
      expect(cubit.state.categories, isEmpty);
      expect(cubit.state.restaurants, isEmpty);
    });

    test('treats a blank stored name as no name', () async {
      final cubit = HomeCubit(
        secureStorageService: _FakeSecureStorageService(userName: '   '),
      );
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, HomeStatus.loaded);
      expect(cubit.state.userName, isNull);
    });

    test('emits a failure state when the profile cannot be read', () async {
      final cubit = HomeCubit(
        secureStorageService: _FakeSecureStorageService(failRead: true),
      );
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.status, HomeStatus.failure);
      expect(cubit.state.hasFailure, isTrue);
      expect(cubit.state.failure?.code, FailureCode.unknown);
    });

    test('recovers on the next load after a failure', () async {
      final storage = _FakeSecureStorageService(
        userName: 'Malak',
        failRead: true,
      );
      final cubit = HomeCubit(secureStorageService: storage);
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.hasFailure, isTrue);

      storage.failRead = false;
      await cubit.load();

      expect(cubit.state.status, HomeStatus.loaded);
      expect(cubit.state.userName, 'Malak');
    });

    test('ignores a second load while the first one is still running',
        () async {
      final storage = _BlockingSecureStorageService();
      final cubit = HomeCubit(secureStorageService: storage);
      addTearDown(cubit.close);

      final states = <HomeState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);

      final first = cubit.load();
      await cubit.load();

      storage.release();
      await first;
      await pumpEventQueue();

      expect(
        states.map((state) => state.status),
        <HomeStatus>[HomeStatus.loading, HomeStatus.loaded],
      );
      expect(storage.reads, 1);
    });
  });
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService({this.userName, this.failRead = false})
      : super(const FlutterSecureStorage());

  String? userName;
  bool failRead;

  @override
  Future<String?> getUserName() async {
    if (failRead) {
      throw StateError('Injected storage failure');
    }
    return userName;
  }
}

/// Holds the profile read open so the loading state can be observed.
class _BlockingSecureStorageService extends SecureStorageService {
  _BlockingSecureStorageService() : super(const FlutterSecureStorage());

  final Completer<void> _gate = Completer<void>();
  int reads = 0;

  void release() => _gate.complete();

  @override
  Future<String?> getUserName() async {
    reads++;
    await _gate.future;
    return 'Malak';
  }
}
