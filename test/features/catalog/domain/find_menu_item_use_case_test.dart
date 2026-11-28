import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:luqma_app/features/catalog/domain/usecases/find_menu_item_use_case.dart';
import '../support/menu_fixtures.dart';

void main() {
  test('finds the actual product on a later page without inventing store data',
      () async {
    final expected = menuItem();
    final repo = FakeMenuRepository()
      ..onItems = (q) async => q.pageNumber == 1
          ? menuPage(number: 1, items: [], next: true, pages: 2)
          : menuPage(number: 2, items: [expected], next: false, pages: 2);
    expect(
        await FindMenuItemUseCase(repo)(expected.id.toUpperCase()), expected);
    expect(repo.queries.map((q) => q.pageNumber), [1, 2]);
    expect(repo.queries.every((q) => q.storeId.isEmpty), isTrue);
  });
  test('returns null only after final page and propagates failures', () async {
    final repo = FakeMenuRepository()
      ..onItems = (_) async => menuPage(items: [], next: false);
    expect(await FindMenuItemUseCase(repo)(menuItem().id), isNull);
    repo.onItems =
        (_) async => throw const FailureException(Failure(FailureCode.network));
    await expectLater(FindMenuItemUseCase(repo)(menuItem().id),
        throwsA(isA<FailureException>()));
    await expectLater(FindMenuItemUseCase(repo)('not-an-id'),
        throwsA(isA<FailureException>()));
  });
}
