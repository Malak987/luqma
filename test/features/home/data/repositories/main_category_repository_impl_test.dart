import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/home/data/datasources/main_category_remote_data_source.dart';
import 'package:luqma_app/features/home/data/models/main_category_model.dart';
import 'package:luqma_app/features/home/data/repositories/main_category_repository_impl.dart';
import 'package:luqma_app/features/home/domain/entities/home_category.dart';

import '../../support/main_category_fixtures.dart';

void main() {
  group('MainCategoryRepositoryImpl', () {
    test(
        'maps every model to an entity and leaves display policy to the use case',
        () async {
      final remote = _FakeRemoteDataSource(models: <MainCategoryModel>[
        MainCategoryModel.fromJson(
            mainCategoryJson(id: 'first', displayOrder: 3)),
        MainCategoryModel.fromJson(
            mainCategoryJson(id: 'second', isActive: false)),
      ]);

      final result =
          await MainCategoryRepositoryImpl(remote).getAllMainCategories();

      expect(result, <HomeCategory>[
        homeCategory(
            id: 'first', displayOrder: 3, iconUrl: mainCategoryIconUrl),
        homeCategory(
            id: 'second', isActive: false, iconUrl: mainCategoryIconUrl),
      ]);
      expect(remote.calls, 1);
    });

    test('keeps successful empty responses empty', () async {
      expect(
        await MainCategoryRepositoryImpl(_FakeRemoteDataSource())
            .getAllMainCategories(),
        isEmpty,
      );
    });

    for (final code in FailureCode.values) {
      test('converts RemoteException $code into the shared FailureException',
          () async {
        final remote = _FakeRemoteDataSource(
          exception: RemoteException(code: code, message: 'Category failure'),
        );
        await expectLater(
          MainCategoryRepositoryImpl(remote).getAllMainCategories(),
          throwsA(isA<FailureException>()
              .having((error) => error.failure.code, 'failure code', code)
              .having((error) => error.failure.debugMessage, 'debug message',
                  'Category failure')),
        );
      });
    }

    test('preserves existing FailureExceptions', () async {
      const failure = FailureException(Failure(FailureCode.network));
      await expectLater(
        MainCategoryRepositoryImpl(_FakeRemoteDataSource(exception: failure))
            .getAllMainCategories(),
        throwsA(same(failure)),
      );
    });

    test('converts unexpected exceptions into an unknown failure', () async {
      await expectLater(
        MainCategoryRepositoryImpl(
                _FakeRemoteDataSource(exception: StateError('unexpected')))
            .getAllMainCategories(),
        throwsA(isA<FailureException>().having((error) => error.failure.code,
            'failure code', FailureCode.unknown)),
      );
    });
  });
}

class _FakeRemoteDataSource implements MainCategoryRemoteDataSource {
  _FakeRemoteDataSource(
      {this.models = const <MainCategoryModel>[], this.exception});

  final List<MainCategoryModel> models;
  final Object? exception;
  int calls = 0;

  @override
  Future<List<MainCategoryModel>> getAllMainCategories() async {
    calls++;
    final error = exception;
    if (error != null) throw error;
    return models;
  }
}
