import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show debugDumpRenderTree;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/catalog/domain/entities/store.dart';
import 'package:luqma_app/features/home/domain/entities/home_category.dart';
import 'package:luqma_app/features/authentication/presentation/cubit/auth_session_cubit.dart';
import 'package:luqma_app/features/home/domain/usecases/get_all_main_categories_use_case.dart';
import 'package:luqma_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:luqma_app/features/home/presentation/pages/home_page.dart';

import '../../support/main_category_fixtures.dart';
import '../../support/store_fixtures.dart';

void main() {
  Future<_FakeSecureStorageService> pumpHome(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    String? userName = 'Malak',
    bool failRead = false,
    Locale locale = const Locale('en'),
    ThemeData? theme,
    FakeMainCategoryRepository? categoryRepository,
    HomeStoreDependencies? storeDependencies,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final storage = _FakeSecureStorageService(
      userName: userName,
      failRead: failRead,
    );
    final categories = categoryRepository ?? FakeMainCategoryRepository();
    final stores = storeDependencies ?? HomeStoreDependencies();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<HomeCubit>(
            create: (_) => HomeCubit(
              secureStorageService: storage,
              getAllMainCategoriesUseCase:
                  GetAllMainCategoriesUseCase(categories),
              getStoresUseCase: stores.useCase,
              catalogPaging: stores.paging,
            ),
          ),
        ],
        child: MaterialApp(
          theme: theme ?? AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: const HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return storage;
  }

  testWidgets('renders the brand header, the search bar and both sections',
      (tester) async {
    await pumpHome(tester);

    expect(find.text('Hello, Malak'), findsOneWidget);
    expect(find.text('Luqma • لقمة'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(
      find.text('Search for your favorite dish or restaurant...'),
      findsOneWidget,
    );
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Restaurants'), findsOneWidget);
    // Empty API data never becomes sample categories or restaurants.
    expect(find.text('No categories are available right now'), findsOneWidget);
    expect(find.text('A restaurants category is not available right now'), findsOneWidget);
  });

  testWidgets('HomePage restaurant retry reaches HomeCubit and recovers',
      (tester) async {
    final categories = FakeMainCategoryRepository(
      categories: <HomeCategory>[homeCategory()],
    );
    final stores = HomeStoreDependencies();
    stores.repository.error = StateError('offline');

    await pumpHome(
      tester,
      categoryRepository: categories,
      storeDependencies: stores,
    );
    _expectNoExceptionWithRenderDump(
      tester,
      'initial HomePage render',
    );
    expect(find.byKey(const Key('home_restaurants_error')), findsOneWidget);
    expect(categories.calls, 1);
    expect(stores.repository.calls, 1);

    stores.repository.error = null;
    stores.repository.stores = const <Store>[testStore];

    final retryButton = find.byKey(const Key('home_restaurants_retry'));
    final homeScrollable = find.descendant(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(Scrollable),
    ).first;
    await tester.scrollUntilVisible(
      retryButton,
      300,
      scrollable: homeScrollable,
    );
    final retryRect = tester.getRect(retryButton);
    final viewportRect = tester.getRect(homeScrollable);
    expect(retryRect.top, greaterThanOrEqualTo(viewportRect.top));
    expect(retryRect.bottom, lessThanOrEqualTo(viewportRect.bottom));
    _expectNoExceptionWithRenderDump(
      tester,
      'scrolling to the retry action',
    );
    await tester.tap(retryButton);
    await tester.pump();
    _expectNoExceptionWithRenderDump(
      tester,
      'retry loading state after tap and pump',
    );
    await tester.pumpAndSettle();

    expect(categories.calls, 1);
    expect(stores.repository.calls, 2);
    expect(find.byKey(const Key('home_restaurants_error')), findsNothing);
    expect(find.text('Nile Kitchen'), findsOneWidget);
    _expectNoExceptionWithRenderDump(
      tester,
      'successful restaurant recovery',
    );
  });

  testWidgets('falls back to a name-less greeting without a stored name',
      (tester) async {
    await pumpHome(tester, userName: null);

    expect(find.text('Welcome'), findsOneWidget);
  });

  testWidgets('renders the Arabic copy when the locale is Arabic',
      (tester) async {
    await pumpHome(tester, locale: const Locale('ar'));

    final homeContext = tester.element(find.byType(HomePage));
    expect(Localizations.localeOf(homeContext).languageCode, 'ar');
    expect(Directionality.of(homeContext), TextDirection.rtl);
    expect(find.text('مرحباً، Malak'), findsOneWidget);
    expect(find.text('Luqma • لقمة'), findsOneWidget);
    expect(find.text('التصنيفات'), findsOneWidget);
    expect(find.text('مطاعم'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a loading indicator while the profile is read',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final storage = _BlockingSecureStorageService();
    final authSessionCubit = AuthSessionCubit(secureStorageService: storage);
    addTearDown(authSessionCubit.close);
    final categories = FakeMainCategoryRepository();
    final stores = HomeStoreDependencies();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<AuthSessionCubit>.value(value: authSessionCubit),
          BlocProvider<HomeCubit>(
            create: (_) => HomeCubit(
              secureStorageService: storage,
              getAllMainCategoriesUseCase:
                  GetAllMainCategoriesUseCase(categories),
              getStoresUseCase: stores.useCase,
              catalogPaging: stores.paging,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const HomePage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Categories'), findsNothing);

    storage.release();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Hello, Malak'), findsOneWidget);
  });

  testWidgets('explains a failed load and retries on demand', (tester) async {
    final storage = await pumpHome(tester, failRead: true);

    expect(find.text("We couldn't load your home screen"), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    storage.failRead = false;
    await tester.tap(find.widgetWithText(ElevatedButton, 'Try again'));
    await tester.pumpAndSettle();

    expect(find.text("We couldn't load your home screen"), findsNothing);
    expect(find.text('Hello, Malak'), findsOneWidget);
  });

  testWidgets('says that search is not available yet', (tester) async {
    await pumpHome(tester);

    await tester.enterText(find.byType(TextFormField), 'pizza');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Search will be available soon'), findsOneWidget);
  });

  testWidgets('does not overflow on a small phone or a wide window',
      (tester) async {
    await pumpHome(tester, size: const Size(320, 568));
    expect(tester.takeException(), isNull);

    await pumpHome(tester, size: const Size(1280, 800), theme: AppTheme.dark);
    expect(tester.takeException(), isNull);
  });
}

/// Preserve and report a framework exception at the phase where it first
/// appears, including the render tree that owns the failing constraints.
void _expectNoExceptionWithRenderDump(WidgetTester tester, String phase) {
  final exception = tester.takeException();
  if (exception != null) {
    debugPrint('Flutter exception during $phase:');
    debugPrint(exception.toString());
    debugPrint('Render tree during $phase:');
    debugDumpRenderTree();
  }

  // Assert on the captured object (rather than calling takeException again),
  // so the diagnostic read cannot swallow the failure.
  expect(
    exception,
    isNull,
    reason: 'Unexpected Flutter exception during $phase: $exception',
  );
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService({this.userName, this.failRead = false})
      : super(const FlutterSecureStorage());

  String? userName;
  bool failRead;
  bool clearCalled = false;

  @override
  Future<String?> getUserName() async {
    if (failRead) {
      throw StateError('Injected storage failure');
    }
    return userName;
  }

  @override
  Future<void> clearAuthData() async {
    clearCalled = true;
  }
}

/// Holds the profile read open so the loading state can be observed.
class _BlockingSecureStorageService extends SecureStorageService {
  _BlockingSecureStorageService() : super(const FlutterSecureStorage());

  final Completer<void> _gate = Completer<void>();

  void release() => _gate.complete();

  @override
  Future<String?> getUserName() async {
    await _gate.future;
    return 'Malak';
  }
}
