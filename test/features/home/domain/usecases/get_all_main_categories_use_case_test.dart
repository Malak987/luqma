import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/home/domain/entities/home_category.dart';
import 'package:luqma_app/features/home/domain/usecases/get_all_main_categories_use_case.dart';

import '../../support/main_category_fixtures.dart';

void main() {
  group('GetAllMainCategoriesUseCase', () {
    test('returns only active categories in ascending displayOrder', () async {
      final first = homeCategory(id: 'first', displayOrder: 1);
      final second = homeCategory(id: 'second', displayOrder: 2);
      final third = homeCategory(id: 'third', displayOrder: 3);
      final inactive = homeCategory(
        id: 'inactive',
        displayOrder: 0,
        isActive: false,
      );
      final original = <HomeCategory>[third, inactive, first, second];
      final repository = FakeMainCategoryRepository(categories: original);

      final result = await GetAllMainCategoriesUseCase(repository)();

      expect(result, <HomeCategory>[first, second, third]);
      expect(repository.calls, 1);
      expect(original, <HomeCategory>[third, inactive, first, second]);
      expect(() => result.add(first), throwsUnsupportedError);
    });

    test('keeps Arabic and English names independent of display order',
        () async {
      final result = await GetAllMainCategoriesUseCase(
        FakeMainCategoryRepository(categories: <HomeCategory>[
          homeCategory(id: 'desserts', nameAr: 'حلويات', nameEn: 'Desserts'),
          homeCategory(id: 'grills', nameAr: 'مشويات', nameEn: 'Grills'),
        ]),
      )();

      expect(result.map((category) => category.nameAr),
          containsAll(['حلويات', 'مشويات']));
      expect(result.map((category) => category.nameEn),
          containsAll(['Desserts', 'Grills']));
    });

    test('returns an empty list for an empty successful response', () async {
      expect(
        await GetAllMainCategoriesUseCase(FakeMainCategoryRepository())(),
        isEmpty,
      );
    });

    test('returns an empty list when all categories are inactive', () async {
      final repository = FakeMainCategoryRepository(
        categories: <HomeCategory>[homeCategory(isActive: false)],
      );

      expect(await GetAllMainCategoriesUseCase(repository)(), isEmpty);
    });

    test('propagates repository failures unchanged, never as an empty list',
        () async {
      const failure = FailureException(
        Failure(FailureCode.network, debugMessage: 'offline'),
      );
      final repository = FakeMainCategoryRepository(exception: failure);

      await expectLater(
        GetAllMainCategoriesUseCase(repository)(),
        throwsA(same(failure)),
      );
    });
  });
}
