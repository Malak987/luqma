import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/network/api_constants.dart';
import 'package:luqma_app/core/network/dio_client.dart';
import 'package:luqma_app/core/presentation/cubit/app_settings_cubit.dart';
import 'package:luqma_app/core/presentation/cubit/app_settings_state.dart';
import 'package:luqma_app/core/storage/preferences_storage_service.dart';
import 'package:luqma_app/core/storage/secure_storage_service.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:luqma_app/core/localization/translations/home_translations.dart';
import 'package:luqma_app/features/home/presentation/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/main_category_fixtures.dart';

/// Exercises the full GetIt -> Dio -> model -> repository -> use case -> cubit
/// -> existing Home grid path. The interceptor resolves every request locally.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Dio dio;
  late _FakeSecureStorageService storage;
  late Object? responseBody;
  late bool failNetwork;
  late int requests;
  Completer<void>? pendingResponse;

  setUp(() async {
    await sl.reset();
    responseBody = mainCategoryEnvelope(data: <Object?>[]);
    failNetwork = false;
    requests = 0;
    pendingResponse = null;
    storage = _FakeSecureStorageService();
    dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
    sl.registerSingleton<SecureStorageService>(storage);
    sl.registerSingleton<DioClient>(DioClient(storage, dio: dio));
    dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) async {
      requests++;
      expect(options.method, 'GET');
      final isCategories = options.path == ApiConstants.getAllMainCategories;
      expect(isCategories || options.path == ApiConstants.getAllStores, isTrue);
      await pendingResponse?.future;
      if (failNetwork) {
        handler.reject(DioException(
            requestOptions: options, type: DioExceptionType.connectionError));
      } else {
        handler.resolve(Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: isCategories
                ? responseBody
                : <String, Object?>{
                    'message': 'success',
                    'data': <String, Object?>{
                      'items': <Object?>[],
                      'pageNumber': 1,
                      'totalPages': 0,
                      'totalCount': 0,
                      'hasPreviousPage': false,
                      'hasNextPage': false,
                    },
                    'isSucceeded': true,
                  }));
      }
    }));
    SharedPreferences.setMockInitialValues(<String, Object>{
      PreferencesStorageService.localeKey: 'en',
    });
    await configureDependencies(
        preferences: await SharedPreferences.getInstance());
  });

  tearDown(() async {
    if (pendingResponse != null && !pendingResponse!.isCompleted) {
      pendingResponse!.complete();
    }
    dio.close(force: true);
    await sl.reset();
  });

  Future<void> pumpHome(WidgetTester tester, {bool settle = true}) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final settings = sl<AppSettingsCubit>();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await settings.close();
    });
    await tester.pumpWidget(MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<AppSettingsCubit>.value(value: settings),
        BlocProvider<HomeCubit>(create: (_) => sl<HomeCubit>()),
      ],
      child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
          builder: (context, state) {
        return MaterialApp(
          theme: AppTheme.light,
          locale: state.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomePage(),
        );
      }),
    ));
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
  }

  testWidgets(
      'displays sorted active API categories without changing the Home shell',
      (tester) async {
    responseBody = mainCategoryEnvelope(data: <Object?>[
      mainCategoryJson(
          id: 'third', nameEn: 'Bakeries', displayOrder: 3, iconUrl: null),
      mainCategoryJson(
          id: 'hidden', nameEn: 'Hidden', displayOrder: 0, isActive: false),
      mainCategoryJson(
          id: 'first', nameEn: 'Grills', displayOrder: 1, iconUrl: null),
      mainCategoryJson(
          id: 'second', nameEn: 'Desserts', displayOrder: 2, iconUrl: null),
    ]);
    await pumpHome(tester);

    final copy = HomeTranslations(const Locale('en'));
    expect(find.text(copy.greeting('Malak')), findsOneWidget);
    expect(find.text(copy.searchHint), findsOneWidget);
    expect(find.text(copy.restaurantsEmpty), findsOneWidget);
    expect(find.byKey(const Key('category_card_hidden')), findsNothing);
    expect(find.byKey(const Key('home_categories_empty')), findsNothing);
    final keys = tester
        .widgetList(find.byWidgetPredicate((widget) {
          final key = widget.key;
          return key is ValueKey<String> &&
              key.value.startsWith('category_card_');
        }))
        .map((widget) => (widget.key! as ValueKey<String>).value);
    expect(keys, <String>[
      'category_card_first',
      'category_card_second',
      'category_card_third',
    ]);
    expect(requests, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changes API names through AppSettingsCubit without refetching',
      (tester) async {
    responseBody = mainCategoryEnvelope(data: <Object?>[
      mainCategoryJson(
          id: 'grills', nameAr: 'مشويات', nameEn: 'Grills', iconUrl: null),
    ]);
    await pumpHome(tester);
    expect(find.text('Grills'), findsOneWidget);
    expect(find.text('مشويات'), findsNothing);

    await tester.tap(find.byTooltip('Language'));
    await tester.pumpAndSettle();
    expect(sl<AppSettingsCubit>().state.locale, const Locale('ar'));
    expect(find.text('مشويات'), findsOneWidget);
    expect(find.text('Grills'), findsNothing);
    expect(requests, 1);

    await tester.tap(find.byTooltip('اللغة'));
    await tester.pumpAndSettle();
    expect(find.text('Grills'), findsOneWidget);
    expect(requests, 1);
  });

  testWidgets('shows section-local loading while the rest of Home is usable',
      (tester) async {
    pendingResponse = Completer<void>();
    await pumpHome(tester, settle: false);
    await tester.pump(const Duration(milliseconds: 10));

    expect(
      find.text(HomeTranslations(const Locale('en')).greeting('Malak')),
      findsOneWidget,
    );
    expect(
      find.text(HomeTranslations(const Locale('en')).searchHint),
      findsOneWidget,
    );
    expect(find.byKey(const Key('home_restaurants_loading')), findsOneWidget);
    expect(find.byKey(const Key('home_categories_loading')), findsOneWidget);
    expect(find.byKey(const Key('home_categories_empty')), findsNothing);

    pendingResponse!.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home_categories_empty')), findsOneWidget);
    expect(requests, 1);
  });

  testWidgets('survives an API failure and retries just the category section',
      (tester) async {
    failNetwork = true;
    await pumpHome(tester);
    expect(find.text("We couldn't load the categories"), findsOneWidget);
    expect(
      find.text(HomeTranslations(const Locale('en')).greeting('Malak')),
      findsOneWidget,
    );
    expect(find.text('A restaurants category is not available right now'), findsOneWidget);
    expect(find.text("We couldn't load your home screen"), findsNothing);
    expect(find.byKey(const Key('home_categories_empty')), findsNothing);

    failNetwork = false;
    responseBody = mainCategoryEnvelope(data: <Object?>[
      mainCategoryJson(
          id: 'recovered', nameEn: 'Recovered category', iconUrl: null),
    ]);
    await tester.tap(find.byKey(const Key('home_categories_retry')));
    await tester.pumpAndSettle();

    expect(find.text('Recovered category'), findsOneWidget);
    expect(find.byKey(const Key('home_categories_error')), findsNothing);
    expect(requests, 2);
    expect(storage.reads, 1);
    expect(tester.takeException(), isNull);
  });

  for (final allInactive in <bool>[false, true]) {
    testWidgets(
        'handles ${allInactive ? 'all-inactive' : 'empty'} API results without a category rail',
        (tester) async {
      responseBody = mainCategoryEnvelope(data: <Object?>[
        if (allInactive) mainCategoryJson(isActive: false),
      ]);
      await pumpHome(tester);
      expect(find.byKey(const Key('home_categories_empty')), findsOneWidget);
      expect(
          find.text('No categories are available right now'), findsOneWidget);
      expect(
          find.byKey(const PageStorageKey('home_categories_rail')), findsNothing);
      expect(find.text('A restaurants category is not available right now'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'malformed successful API data shows retry, not an empty result or crash',
      (tester) async {
    responseBody = mainCategoryEnvelope(
        data: <Object?>[mainCategoryJson()..remove('nameAr')]);
    await pumpHome(tester);
    expect(find.byKey(const Key('home_categories_error')), findsOneWidget);
    expect(find.byKey(const Key('home_categories_retry')), findsOneWidget);
    expect(find.byKey(const Key('home_categories_empty')), findsNothing);
    expect(
      find.text(HomeTranslations(const Locale('en')).greeting('Malak')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService() : super(const FlutterSecureStorage());

  int reads = 0;

  @override
  Future<String?> getUserName() async {
    reads++;
    return 'Malak';
  }
}
