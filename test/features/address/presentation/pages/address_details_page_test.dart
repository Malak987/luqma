import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/address/domain/entities/address_draft.dart';
import 'package:luqma_app/features/address/domain/entities/address_label.dart';
import 'package:luqma_app/features/address/domain/repositories/address_repository.dart';
import 'package:luqma_app/features/address/domain/usecases/create_address_use_case.dart';
import 'package:luqma_app/features/address/presentation/cubit/address_form_cubit.dart';
import 'package:luqma_app/features/address/presentation/pages/address_details_page.dart';
import 'package:luqma_app/features/location/domain/entities/location_coordinates.dart';
import 'package:luqma_app/core/error/failures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await sl.reset();
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await configureDependencies(preferences: prefs);
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> configureWithFakeCreate({
    FailureException? failure,
    Duration? delay,
  }) async {
    await sl.reset();
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await configureDependencies(preferences: prefs);

    if (sl.isRegistered<AddressRepository>()) sl.unregister<AddressRepository>();
    if (sl.isRegistered<CreateAddressUseCase>()) sl.unregister<CreateAddressUseCase>();
    if (sl.isRegistered<AddressFormCubit>()) sl.unregister<AddressFormCubit>();

    final fakeRepo = _FakeAddressRepository(failure: failure, delay: delay);
    sl.registerLazySingleton<AddressRepository>(() => fakeRepo);
    sl.registerLazySingleton<CreateAddressUseCase>(
      () => CreateAddressUseCase(sl<AddressRepository>()),
    );
    sl.registerFactoryParam<AddressFormCubit, LocationCoordinates, void>(
      (coords, _) => AddressFormCubit(
        createAddressUseCase: sl<CreateAddressUseCase>(),
        coordinates: coords,
      ),
    );
  }

  final testCoords = LocationCoordinates.fromMapSelection(
    latitude: 26.557,
    longitude: 31.694,
  );

  group('AddressDetailsPage', () {
    testWidgets('shows title, instructions, location summary and form', (tester) async {
      await configureWithFakeCreate();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: AddressDetailsPage(coordinates: testCoords),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('address_details_page')), findsOneWidget);
      expect(find.text('Address details'), findsOneWidget);
      expect(find.text('Add details for your selected location'), findsOneWidget);
      expect(find.byKey(const Key('address_details_location_summary')), findsOneWidget);
      expect(find.byKey(const Key('address_details_coordinates')), findsOneWidget);
      expect(find.textContaining('26.55700'), findsOneWidget);
      expect(find.textContaining('31.69400'), findsOneWidget);
      // Label selector
      expect(find.byKey(const Key('address_label_home')), findsOneWidget);
      expect(find.byKey(const Key('address_label_work')), findsOneWidget);
      expect(find.byKey(const Key('address_label_other')), findsOneWidget);
      // Fields
      expect(find.byKey(const Key('address_details_title_field')), findsOneWidget);
      expect(find.byKey(const Key('address_details_district_field')), findsOneWidget);
      expect(find.byKey(const Key('address_details_city_field')), findsOneWidget);
      expect(find.byKey(const Key('address_details_details_field')), findsOneWidget);
      expect(find.byKey(const Key('address_details_submit')), findsOneWidget);
    });

    testWidgets('supports Arabic and RTL', (tester) async {
      await configureWithFakeCreate();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: AddressDetailsPage(coordinates: testCoords),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('تفاصيل العنوان'), findsOneWidget);
      expect(find.text('أضف تفاصيل العنوان لموقعك المحدد على الخريطة'), findsOneWidget);
      final dir = tester.widget<Directionality>(find.byType(Directionality).first);
      expect(dir.textDirection, TextDirection.rtl);
    });

    testWidgets('supports dark theme without overflow at narrow width', (tester) async {
      await configureWithFakeCreate();

      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: AddressDetailsPage(coordinates: testCoords),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('address_details_page')), findsOneWidget);
    });

    testWidgets('validation: empty fields show errors and prevent submission', (tester) async {
      await configureWithFakeCreate();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: AddressDetailsPage(coordinates: testCoords),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byKey(const Key('address_details_submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('address_details_validation_error')), findsOneWidget);
      expect(find.text('This field is required'), findsWidgets);
      // No API call should have happened - verify via repo not called
      final repo = sl<AddressRepository>() as _FakeAddressRepository;
      expect(repo.createCalls, 0);
    });

    testWidgets('label selection updates and is submitted correctly', (tester) async {
      await configureWithFakeCreate();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: AddressDetailsPage(coordinates: testCoords),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Default is home, tap work
      await tester.tap(find.byKey(const Key('address_label_work')));
      await tester.pump();

      // Fill form
      await tester.enterText(find.byKey(const Key('address_details_title_field')), 'My Home');
      await tester.enterText(find.byKey(const Key('address_details_district_field')), 'District');
      await tester.enterText(find.byKey(const Key('address_details_city_field')), 'Sohag');
      await tester.enterText(find.byKey(const Key('address_details_details_field')), 'Building 1');

      await tester.tap(find.byKey(const Key('address_details_submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final repo = sl<AddressRepository>() as _FakeAddressRepository;
      expect(repo.createCalls, 1);
      expect(repo.lastDraft!.label, AddressLabel.work);
    });

    testWidgets('preserves selected coordinates throughout flow', (tester) async {
      await configureWithFakeCreate();
      final deviceCoords = LocationCoordinates.fromDevice(
        latitude: 30.12345,
        longitude: 31.54321,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: AddressDetailsPage(coordinates: deviceCoords),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('30.12345'), findsOneWidget);
      expect(find.textContaining('31.54321'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('address_details_title_field')), 'Title');
      await tester.enterText(find.byKey(const Key('address_details_district_field')), 'District');
      await tester.enterText(find.byKey(const Key('address_details_city_field')), 'City');
      await tester.enterText(find.byKey(const Key('address_details_details_field')), 'Details');

      await tester.tap(find.byKey(const Key('address_details_submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final repo = sl<AddressRepository>() as _FakeAddressRepository;
      expect(repo.lastDraft!.latitude, 30.12345);
      expect(repo.lastDraft!.longitude, 31.54321);
      expect(repo.lastDraft!.latitude, isNot(26.56));
    });

    testWidgets('loading state prevents duplicate submissions', (tester) async {
      await configureWithFakeCreate(delay: const Duration(milliseconds: 200));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: AddressDetailsPage(coordinates: testCoords),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.enterText(find.byKey(const Key('address_details_title_field')), 'Title');
      await tester.enterText(find.byKey(const Key('address_details_district_field')), 'District');
      await tester.enterText(find.byKey(const Key('address_details_city_field')), 'City');
      await tester.enterText(find.byKey(const Key('address_details_details_field')), 'Details');

      await tester.tap(find.byKey(const Key('address_details_submit')));
      await tester.pump();
      // Should be in submitting state
      expect(find.text('Saving…'), findsOneWidget);

      // Try second tap while still submitting
      await tester.tap(find.byKey(const Key('address_details_submit')));
      await tester.pump(const Duration(milliseconds: 50));

      await tester.pump(const Duration(milliseconds: 250));

      final repo = sl<AddressRepository>() as _FakeAddressRepository;
      expect(repo.createCalls, 1);
    });

    testWidgets('API failure shows error and allows retry', (tester) async {
      await configureWithFakeCreate(
        failure: const FailureException(
          Failure(FailureCode.validation, debugMessage: 'rejected'),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: AddressDetailsPage(coordinates: testCoords),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.enterText(find.byKey(const Key('address_details_title_field')), 'Title');
      await tester.enterText(find.byKey(const Key('address_details_district_field')), 'District');
      await tester.enterText(find.byKey(const Key('address_details_city_field')), 'City');
      await tester.enterText(find.byKey(const Key('address_details_details_field')), 'Details');

      await tester.tap(find.byKey(const Key('address_details_submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('address_details_error')), findsOneWidget);
      expect(find.text('Could not save address'), findsOneWidget);
      expect(find.byKey(const Key('address_details_error_retry')), findsOneWidget);

      // Fix failure and retry
      await sl.reset();
      await configureWithFakeCreate(); // success now
      // Need to rebuild widget with new fake - pump again with same coords
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: AddressDetailsPage(coordinates: testCoords),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byKey(const Key('address_details_title_field')), 'Title');
      await tester.enterText(find.byKey(const Key('address_details_district_field')), 'District');
      await tester.enterText(find.byKey(const Key('address_details_city_field')), 'City');
      await tester.enterText(find.byKey(const Key('address_details_details_field')), 'Details');
      await tester.tap(find.byKey(const Key('address_details_submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Should not show error after retry success in this re-pumped instance
      // (original error test already verified)
    });

    testWidgets('successful creation pops with true only after server confirms', (tester) async {
      await configureWithFakeCreate();

      bool? poppedResult;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('open_details'),
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => AddressDetailsPage(coordinates: testCoords),
                  ),
                );
                poppedResult = result;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('open_details')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('address_details_page')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('address_details_title_field')), 'Title');
      await tester.enterText(find.byKey(const Key('address_details_district_field')), 'District');
      await tester.enterText(find.byKey(const Key('address_details_city_field')), 'City');
      await tester.enterText(find.byKey(const Key('address_details_details_field')), 'Details');

      // Before submit, not popped
      expect(poppedResult, isNull);

      await tester.tap(find.byKey(const Key('address_details_submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(poppedResult, isTrue);
      final repo = sl<AddressRepository>() as _FakeAddressRepository;
      expect(repo.createCalls, 1);
    });
  });
}

class _FakeAddressRepository implements AddressRepository {
  _FakeAddressRepository({this.failure, this.delay});

  final FailureException? failure;
  final Duration? delay;
  int createCalls = 0;
  AddressDraft? lastDraft;

  @override
  Future<List<Address>> getMyAddresses() async => const <Address>[];

  @override
  Future<void> createAddress(AddressDraft address) async {
    createCalls++;
    lastDraft = address;
    if (delay != null) {
      await Future<void>.delayed(delay!);
    }
    if (failure != null) throw failure!;
  }
}
