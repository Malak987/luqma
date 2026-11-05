import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/address/presentation/cubit/map_picker_cubit.dart';
import 'package:luqma_app/features/address/presentation/pages/map_location_picker_page.dart';
import 'package:luqma_app/features/location/domain/entities/current_location_outcome.dart';
import 'package:luqma_app/features/location/domain/entities/location_coordinates.dart';
import 'package:luqma_app/features/location/domain/repositories/location_repository.dart';
import 'package:luqma_app/features/location/domain/usecases/get_current_location_use_case.dart';
import 'package:luqma_app/features/location/domain/usecases/request_location_permission_use_case.dart';
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

  // Helper to configure GetIt with controllable fakes
  Future<void> configureWithFakes({
    required CurrentLocationOutcome getCurrentOutcome,
    CurrentLocationOutcome? requestOutcome,
    Completer<CurrentLocationOutcome>? getCurrentCompleter,
  }) async {
    await sl.reset();
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await configureDependencies(preferences: prefs);

    if (sl.isRegistered<LocationRepository>()) sl.unregister<LocationRepository>();
    if (sl.isRegistered<GetCurrentLocationUseCase>()) sl.unregister<GetCurrentLocationUseCase>();
    if (sl.isRegistered<RequestLocationPermissionUseCase>()) {
      sl.unregister<RequestLocationPermissionUseCase>();
    }
    if (sl.isRegistered<MapPickerCubit>()) sl.unregister<MapPickerCubit>();

    final fakeRepo = _FakeLocationRepository(
      getCurrentOutcome: getCurrentOutcome,
      requestOutcome: requestOutcome ?? getCurrentOutcome,
      getCurrentCompleter: getCurrentCompleter,
    );
    sl.registerLazySingleton<LocationRepository>(() => fakeRepo);
    sl.registerLazySingleton<GetCurrentLocationUseCase>(
      () => GetCurrentLocationUseCase(sl<LocationRepository>()),
    );
    sl.registerLazySingleton<RequestLocationPermissionUseCase>(
      () => RequestLocationPermissionUseCase(sl<LocationRepository>()),
    );
    sl.registerFactory<MapPickerCubit>(
      () => MapPickerCubit(
        getCurrentLocationUseCase: sl<GetCurrentLocationUseCase>(),
        requestLocationPermissionUseCase: sl<RequestLocationPermissionUseCase>(),
      ),
    );
  }

  // Fake map builder for deterministic tests without network tiles
  Widget fakeMapBuilder(
    BuildContext context,
    LocationCoordinates center,
    ValueChanged<LatLng> onMapMoved,
    bool isDark,
  ) {
    return Container(
      key: const Key('map_picker_map_fake'),
      color: isDark ? Colors.black : Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FakeMap ${center.latitude},${center.longitude}',
              key: const Key('fake_map_center'),
            ),
            ElevatedButton(
              key: const Key('fake_map_move_button'),
              onPressed: () => onMapMoved(const LatLng(30.0, 31.0)),
              child: const Text('Move'),
            ),
            // Center pin stub
            const Icon(Icons.location_on, key: Key('map_picker_center_pin')),
          ],
        ),
      ),
    );
  }

  group('MapLocationPickerPage', () {
    testWidgets('shows loading then fallback when GPS denied', (tester) async {
      final completer = Completer<CurrentLocationOutcome>();
      await configureWithFakes(
        getCurrentOutcome: const LocationPermissionDenied(),
        getCurrentCompleter: completer,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(mapBuilder: fakeMapBuilder),
        ),
      );

      // Initially loading
      await tester.pump();
      expect(find.byKey(const Key('map_picker_loading')), findsOneWidget);

      // Complete with denied -> fallback
      completer.complete(const LocationPermissionDenied());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('map_picker_page')), findsOneWidget);
      expect(find.byKey(const Key('map_picker_fallback_indicator')), findsOneWidget);
      expect(find.textContaining('Approximate location (Sohag)'), findsOneWidget);
      expect(find.byKey(const Key('map_picker_coordinates')), findsOneWidget);
      // Coordinates should be Sohag 26.56,31.69
      expect(find.textContaining('26.56000'), findsOneWidget);
      expect(find.textContaining('31.69000'), findsOneWidget);
      // Fallback must not be labelled as device
      expect(find.text('Your device location'), findsNothing);
      expect(find.text('Approximate location'), findsOneWidget);
    });

    testWidgets('shows device location when GPS available', (tester) async {
      final device = LocationCoordinates.fromDevice(latitude: 30.0444, longitude: 31.2357);
      await configureWithFakes(
        getCurrentOutcome: CurrentLocationSuccess(device),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(mapBuilder: fakeMapBuilder),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('map_picker_fallback_indicator')), findsNothing);
      expect(find.textContaining('30.04440'), findsOneWidget);
      expect(find.textContaining('31.23570'), findsOneWidget);
      expect(find.text('Your device location'), findsOneWidget);
      expect(find.text('Approximate location'), findsNothing);
    });

    testWidgets('manual map movement updates coordinates and clears fallback',
        (tester) async {
      await configureWithFakes(
        getCurrentOutcome: const LocationServiceDisabled(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(mapBuilder: fakeMapBuilder),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('map_picker_fallback_indicator')), findsOneWidget);

      // Simulate manual move via fake button
      await tester.tap(find.byKey(const Key('fake_map_move_button')));
      await tester.pump();

      expect(find.textContaining('30.00000'), findsOneWidget);
      expect(find.textContaining('31.00000'), findsOneWidget);
      // Fallback indicator should disappear after manual move
      expect(find.byKey(const Key('map_picker_fallback_indicator')), findsNothing);
    });

    testWidgets('recenter success updates to device location', (tester) async {
      final device = LocationCoordinates.fromDevice(latitude: 29.9, longitude: 31.0);
      // First call denied, second (recenter) success
      final repo = _SequencedFakeRepository(
        getCurrentOutcomes: [
          const LocationPermissionDenied(),
          CurrentLocationSuccess(device),
        ],
        requestOutcomes: [
          CurrentLocationSuccess(device),
        ],
      );
      await sl.reset();
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await configureDependencies(preferences: prefs);
      if (sl.isRegistered<LocationRepository>()) sl.unregister<LocationRepository>();
      if (sl.isRegistered<GetCurrentLocationUseCase>()) sl.unregister<GetCurrentLocationUseCase>();
      if (sl.isRegistered<RequestLocationPermissionUseCase>()) {
        sl.unregister<RequestLocationPermissionUseCase>();
      }
      if (sl.isRegistered<MapPickerCubit>()) sl.unregister<MapPickerCubit>();
      sl.registerLazySingleton<LocationRepository>(() => repo);
      sl.registerLazySingleton<GetCurrentLocationUseCase>(
        () => GetCurrentLocationUseCase(sl<LocationRepository>()),
      );
      sl.registerLazySingleton<RequestLocationPermissionUseCase>(
        () => RequestLocationPermissionUseCase(sl<LocationRepository>()),
      );
      sl.registerFactory<MapPickerCubit>(
        () => MapPickerCubit(
          getCurrentLocationUseCase: sl<GetCurrentLocationUseCase>(),
          requestLocationPermissionUseCase: sl<RequestLocationPermissionUseCase>(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(mapBuilder: fakeMapBuilder),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('map_picker_fallback_indicator')), findsOneWidget);

      await tester.tap(find.byKey(const Key('map_picker_recenter_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('29.90000'), findsOneWidget);
      expect(find.byKey(const Key('map_picker_fallback_indicator')), findsNothing);
    });

    testWidgets('recenter with permission denied keeps fallback and shows error',
        (tester) async {
      await configureWithFakes(
        getCurrentOutcome: const LocationPermissionDenied(),
        requestOutcome: const LocationPermissionDenied(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(mapBuilder: fakeMapBuilder),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byKey(const Key('map_picker_recenter_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('map_picker_fallback_indicator')), findsOneWidget);
      expect(find.byKey(const Key('map_picker_error')), findsOneWidget);
      expect(find.textContaining('denied'), findsOneWidget);
    });

    testWidgets('recenter with service disabled shows error', (tester) async {
      await configureWithFakes(
        getCurrentOutcome: const LocationServiceDisabled(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(mapBuilder: fakeMapBuilder),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byKey(const Key('map_picker_recenter_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('map_picker_error')), findsOneWidget);
      expect(find.textContaining('disabled'), findsOneWidget);
    });

    testWidgets('confirm returns correct coordinates via callback', (tester) async {
      final device = LocationCoordinates.fromDevice(latitude: 30.5, longitude: 31.5);
      await configureWithFakes(
        getCurrentOutcome: CurrentLocationSuccess(device),
      );

      LocationCoordinates? confirmed;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(
            mapBuilder: fakeMapBuilder,
            onConfirmed: (c) => confirmed = c,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byKey(const Key('map_picker_confirm_button')));
      await tester.pump();

      expect(confirmed, isNotNull);
      expect(confirmed!.latitude, 30.5);
      expect(confirmed!.longitude, 31.5);
      expect(confirmed!.isDeviceDetected, isTrue);
    });

    testWidgets('confirm after manual move returns moved coordinates', (tester) async {
      await configureWithFakes(
        getCurrentOutcome: const LocationServiceDisabled(),
      );

      LocationCoordinates? confirmed;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(
            mapBuilder: fakeMapBuilder,
            onConfirmed: (c) => confirmed = c,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byKey(const Key('fake_map_move_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('map_picker_confirm_button')));
      await tester.pump();

      expect(confirmed!.latitude, 30.0);
      expect(confirmed!.longitude, 31.0);
      expect(confirmed!.source, LocationCoordinateSource.mapSelection);
    });

    testWidgets('shows attribution', (tester) async {
      await configureWithFakes(
        getCurrentOutcome: const LocationPermissionDenied(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(mapBuilder: fakeMapBuilder),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('map_picker_attribution')), findsOneWidget);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
    });

    testWidgets('supports Arabic and RTL', (tester) async {
      await configureWithFakes(
        getCurrentOutcome: const LocationPermissionDenied(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: MapLocationPickerPage(mapBuilder: fakeMapBuilder),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('اختر الموقع'), findsOneWidget);
      expect(find.text('حرك الخريطة حتى يشير الدبوس إلى موقعك بدقة'), findsOneWidget);
      expect(find.text('تأكيد الموقع'), findsOneWidget);
      expect(find.text('موقع تقريبي (سوهاج) — حرك الخريطة أو اضغط إعادة التمركز'), findsOneWidget);
      // Check RTL direction
      final dir = tester.widget<Directionality>(find.byType(Directionality).first);
      expect(dir.textDirection, TextDirection.rtl);
    });

    testWidgets('supports dark theme without overflow', (tester) async {
      await configureWithFakes(
        getCurrentOutcome: const LocationPermissionDenied(),
      );

      await tester.binding.setSurfaceSize(const Size(320, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(mapBuilder: fakeMapBuilder),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('map_picker_page')), findsOneWidget);
    });

    testWidgets('does not trigger reverse geocoding on move', (tester) async {
      // This test ensures MapPickerCubit has no reverse geocoding dependency
      // and that moving the map does not attempt reverse geocoding.
      // We verify by checking the cubit was created without that use-case.
      await configureWithFakes(
        getCurrentOutcome: const LocationPermissionDenied(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(mapBuilder: fakeMapBuilder),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Move map — should not throw or require reverse geocoding
      await tester.tap(find.byKey(const Key('fake_map_move_button')));
      await tester.pump();

      // If reverse geocoding were incorrectly wired, this would fail or show error
      expect(find.byKey(const Key('map_picker_error')), findsNothing);
      expect(find.textContaining('30.00000'), findsOneWidget);
    });

    testWidgets('async initial GPS success moves camera to device coordinates',
        (tester) async {
      // Simulate pending initial GPS that resolves to device after map built with fallback
      final completer = Completer<CurrentLocationOutcome>();
      LatLng? lastCenterSeen;
      Widget capturingBuilder(
        BuildContext context,
        LocationCoordinates center,
        ValueChanged<LatLng> onMapMoved,
        bool isDark,
      ) {
        lastCenterSeen = LatLng(center.latitude, center.longitude);
        return fakeMapBuilder(context, center, onMapMoved, isDark);
      }

      await configureWithFakes(
        getCurrentOutcome: const LocationPermissionDenied(),
        getCurrentCompleter: completer,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(mapBuilder: capturingBuilder),
        ),
      );

      await tester.pump(); // loading
      expect(find.byKey(const Key('map_picker_loading')), findsOneWidget);

      final device = LocationCoordinates.fromDevice(latitude: 30.12345, longitude: 31.54321);
      completer.complete(CurrentLocationSuccess(device));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Camera should have received device coordinates (via BlocListener move).
      // Verify via stable key to avoid duplicate finder (fake_map_center + coordinates label).
      expect(lastCenterSeen, isNotNull);
      expect(lastCenterSeen!.latitude, closeTo(30.12345, 1e-5));
      expect(lastCenterSeen!.longitude, closeTo(31.54321, 1e-5));
      // Use existing stable key `fake_map_center` to verify map builder received device coordinates
      final fakeCenterText =
          tester.widget<Text>(find.byKey(const Key('fake_map_center'))).data!;
      expect(fakeCenterText, contains('30.12345'));
      expect(fakeCenterText, contains('31.54321'));
      // Displayed coordinates and fallback indicator assertions (separate from map center)
      expect(find.byKey(const Key('map_picker_coordinates')), findsOneWidget);
      expect(find.byKey(const Key('map_picker_fallback_indicator')), findsNothing);
    });

    testWidgets('RTL attribution visible and not overlapping recenter at narrow width',
        (tester) async {
      await configureWithFakes(
        getCurrentOutcome: const LocationPermissionDenied(),
      );

      await tester.binding.setSurfaceSize(const Size(320, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // LTR
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(mapBuilder: fakeMapBuilder),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify LTR directionality inherited by overlay (not just outermost)
      final ltrDir = tester.widget<Directionality>(
        find.ancestor(
          of: find.byKey(const Key('map_picker_attribution')),
          matching: find.byType(Directionality),
        ).first,
      );
      expect(ltrDir.textDirection, TextDirection.ltr,
          reason: 'Overlay should inherit LTR from MaterialApp locale en');

      final attrRectEn = tester.getRect(find.byKey(const Key('map_picker_attribution')));
      final recenterRectEn = tester.getRect(find.byKey(const Key('map_picker_recenter_button')));
      expect(attrRectEn, isNotNull);
      expect(recenterRectEn, isNotNull);
      expect(attrRectEn.overlaps(recenterRectEn), isFalse,
          reason: 'Attribution and recenter must not overlap at 320 width LTR');

      // RTL — ensure overlay inherits RTL from Arabic locale
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: MapLocationPickerPage(mapBuilder: fakeMapBuilder),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final rtlDir = tester.widget<Directionality>(
        find.ancestor(
          of: find.byKey(const Key('map_picker_attribution')),
          matching: find.byType(Directionality),
        ).first,
      );
      expect(rtlDir.textDirection, TextDirection.rtl,
          reason: 'Overlay must inherit RTL from Arabic locale for PositionedDirectional to mirror');

      final attrRectAr = tester.getRect(find.byKey(const Key('map_picker_attribution')));
      final recenterRectAr = tester.getRect(find.byKey(const Key('map_picker_recenter_button')));
      expect(attrRectAr, isNotNull);
      expect(recenterRectAr, isNotNull);
      expect(attrRectAr.overlaps(recenterRectAr), isFalse,
          reason: 'Attribution and recenter must not overlap at 320 width RTL');
      // In RTL, attribution (start) should be on the right (mirrored vs LTR)
      expect(attrRectAr.left, greaterThan(attrRectEn.left),
          reason: 'RTL attribution should be mirrored to opposite side');
    });

    testWidgets('fallback without error banner on expected denied', (tester) async {
      await configureWithFakes(
        getCurrentOutcome: const LocationPermissionDenied(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(mapBuilder: fakeMapBuilder),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('map_picker_fallback_indicator')), findsOneWidget);
      expect(find.byKey(const Key('map_picker_error')), findsNothing);
    });

    testWidgets('retrieval failure shows error with fallback', (tester) async {
      await configureWithFakes(
        getCurrentOutcome: const LocationRetrievalFailure(
          LocationFailureReason.positionRetrievalFailed,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(mapBuilder: fakeMapBuilder),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('map_picker_fallback_indicator')), findsOneWidget);
      expect(find.byKey(const Key('map_picker_error')), findsOneWidget);
    });
  });
}

class _FakeLocationRepository implements LocationRepository {
  _FakeLocationRepository({
    required this.getCurrentOutcome,
    required this.requestOutcome,
    this.getCurrentCompleter,
  });

  final CurrentLocationOutcome getCurrentOutcome;
  final CurrentLocationOutcome requestOutcome;
  final Completer<CurrentLocationOutcome>? getCurrentCompleter;

  @override
  Future<CurrentLocationOutcome> getCurrentLocation() {
    if (getCurrentCompleter != null) return getCurrentCompleter!.future;
    return Future.value(getCurrentOutcome);
  }

  @override
  Future<CurrentLocationOutcome> requestLocationPermission({
    required LocationPermissionRequestMode mode,
  }) async {
    return requestOutcome;
  }
}

class _SequencedFakeRepository implements LocationRepository {
  _SequencedFakeRepository({
    required this.getCurrentOutcomes,
    required this.requestOutcomes,
  });

  final List<CurrentLocationOutcome> getCurrentOutcomes;
  final List<CurrentLocationOutcome> requestOutcomes;
  int _getIndex = 0;
  int _reqIndex = 0;

  @override
  Future<CurrentLocationOutcome> getCurrentLocation() async {
    final result = getCurrentOutcomes[_getIndex.clamp(0, getCurrentOutcomes.length - 1)];
    if (_getIndex < getCurrentOutcomes.length - 1) _getIndex++;
    return result;
  }

  @override
  Future<CurrentLocationOutcome> requestLocationPermission({
    required LocationPermissionRequestMode mode,
  }) async {
    final result = requestOutcomes[_reqIndex.clamp(0, requestOutcomes.length - 1)];
    if (_reqIndex < requestOutcomes.length - 1) _reqIndex++;
    return result;
  }
}
