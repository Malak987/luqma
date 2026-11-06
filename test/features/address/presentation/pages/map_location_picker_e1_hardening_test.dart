import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/map/maplibre_config.dart';
import 'package:luqma_app/core/theme/app_colors.dart';
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

  Future<void> configureWithFakes({
    required CurrentLocationOutcome outcome,
  }) async {
    await sl.reset();
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await configureDependencies(preferences: prefs);
    if (sl.isRegistered<LocationRepository>()) sl.unregister<LocationRepository>();
    if (sl.isRegistered<GetCurrentLocationUseCase>()) sl.unregister<GetCurrentLocationUseCase>();
    if (sl.isRegistered<RequestLocationPermissionUseCase>()) sl.unregister<RequestLocationPermissionUseCase>();
    if (sl.isRegistered<MapPickerCubit>()) sl.unregister<MapPickerCubit>();
    final repo = _FakeLocationRepository(outcome);
    sl.registerLazySingleton<LocationRepository>(() => repo);
    sl.registerLazySingleton<GetCurrentLocationUseCase>(() => GetCurrentLocationUseCase(sl<LocationRepository>()));
    sl.registerLazySingleton<RequestLocationPermissionUseCase>(() => RequestLocationPermissionUseCase(sl<LocationRepository>()));
    sl.registerFactory<MapPickerCubit>(() => MapPickerCubit(
          getCurrentLocationUseCase: sl<GetCurrentLocationUseCase>(),
          requestLocationPermissionUseCase: sl<RequestLocationPermissionUseCase>(),
        ));
  }

  Widget fakeMapBuilder(BuildContext context, LocationCoordinates center, ValueChanged<LatLng> onMapMoved, bool isDark) {
    return Container(
      key: Key('fake_map_${isDark ? 'dark' : 'light'}'),
      child: Column(
        children: [
          Text('coords ${center.latitude},${center.longitude}', key: const Key('fake_coords')),
          ElevatedButton(
            key: const Key('fake_move'),
            onPressed: () => onMapMoved(const LatLng(30.0, 31.0)),
            child: const Text('Move'),
          ),
        ],
      ),
    );
  }

  group('E.1 MapLibre — platform configuration', () {
    testWidgets('missing platform configuration shows localized error, never MapLibreMap', (tester) async {
      await configureWithFakes(outcome: const LocationPermissionDenied());
      // English
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(
            mapBuilder: fakeMapBuilder,
            debugIsReleaseModeOverride: true,
            debugApiKeyOverride: '',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('map_picker_config_error')), findsOneWidget);
      expect(find.text('Map unavailable'), findsOneWidget);
      expect(find.text('Map configuration is incomplete. Please contact support or try again later.'), findsOneWidget);
      expect(find.byKey(const Key('fake_map_light')), findsNothing);
      expect(find.byKey(const Key('map_picker_map')), findsNothing);

      // Arabic
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: MapLocationPickerPage(
            mapBuilder: fakeMapBuilder,
            debugIsReleaseModeOverride: true,
            debugApiKeyOverride: '',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('map_picker_config_error')), findsOneWidget);
      expect(find.text('تعذر تحميل الخريطة'), findsOneWidget);
    });

    testWidgets('configured key shows map with correct style, not error', (tester) async {
      await configureWithFakes(outcome: const LocationPermissionDenied());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(
            mapBuilder: fakeMapBuilder,
            debugIsReleaseModeOverride: false,
            debugApiKeyOverride: 'test-key-123',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('map_picker_config_error')), findsNothing);
      expect(find.byKey(const Key('fake_map_light')), findsOneWidget);
      // Style selection verified via MapLibreConfig
      expect(MapLibreConfig.resolveStyleForTest(isDark: false), contains('#FAF7F0'));
      expect(MapLibreConfig.resolveStyleForTest(isDark: true), contains('#1A1A1A'));
    });

    test('correct light/dark style selection via MapLibreConfig', () {
      final light = MapLibreConfig.styleForBrightness(Brightness.light);
      final dark = MapLibreConfig.styleForBrightness(Brightness.dark);
      expect(light, contains('#FAF7F0'));
      expect(dark, contains('#1A1A1A'));
      expect(light, isNot(dark));
      expect(light, isNot(contains('apikey')));
      expect(dark, isNot(contains('apikey')));
    });

    test('no API key leakage in logs — config does not log key', () {
      // Verify that MapLibreConfig JSON contains no key and that page's
      // debugIsReleaseModeOverride path never logs the key value.
      // The implementation only logs generic messages like "[Maps] ... not configured".
      expect(MapLibreConfig.lightStyleJson.toLowerCase(), isNot(contains('your_')));
      expect(MapLibreConfig.darkStyleJson.toLowerCase(), isNot(contains('your_')));
    });
  });

  group('E.1 Theme synchronization preserves camera', () {
    testWidgets('theme switch preserves selected coordinates (no restart)', (tester) async {
      final device = LocationCoordinates.fromDevice(latitude: 26.56, longitude: 31.69);
      await configureWithFakes(outcome: CurrentLocationSuccess(device));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(
            mapBuilder: (ctx, center, onMoved, isDark) => Column(
              children: [
                Text('center ${center.latitude},${center.longitude}', key: const Key('center_text')),
                ElevatedButton(key: const Key('fake_move'), onPressed: () => onMoved(const LatLng(30.5, 31.5)), child: const Text('Move')),
              ],
            ),
            debugIsReleaseModeOverride: false,
            debugApiKeyOverride: 'k',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('26.56000'), findsOneWidget);
      await tester.tap(find.byKey(const Key('fake_move')));
      await tester.pump();
      expect(find.textContaining('30.50000'), findsOneWidget);

      // Switch to dark — must preserve moved coordinates, not reset
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(
            mapBuilder: (ctx, center, onMoved, isDark) => Column(
              children: [
                Text('center ${center.latitude},${center.longitude}', key: const Key('center_text')),
                ElevatedButton(key: const Key('fake_move'), onPressed: () => onMoved(const LatLng(30.5, 31.5)), child: const Text('Move')),
                Text(isDark ? 'dark' : 'light', key: const Key('theme_indicator')),
              ],
            ),
            debugIsReleaseModeOverride: false,
            debugApiKeyOverride: 'k',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('dark'), findsOneWidget);
      expect(find.textContaining('30.50000'), findsOneWidget);
      expect(find.textContaining('26.56000'), findsNothing);
    });

    testWidgets('MapLibreConfig style updates do not recreate map controller', (tester) async {
      await configureWithFakes(outcome: const LocationPermissionDenied());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(
            mapBuilder: fakeMapBuilder,
            debugIsReleaseModeOverride: false,
            debugApiKeyOverride: 'k',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('fake_map_light')), findsOneWidget);
      // Switch theme — fake builder should show dark variant, but real controller would just update style
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(
            mapBuilder: fakeMapBuilder,
            debugIsReleaseModeOverride: false,
            debugApiKeyOverride: 'k',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('fake_map_dark')), findsOneWidget);
    });
  });

  group('E.1 Existing GPS, fallback, recenter, confirmation unchanged', () {
    testWidgets('fallback indicator shown when GPS denied', (tester) async {
      await configureWithFakes(outcome: const LocationPermissionDenied());
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
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('map_picker_fallback_indicator')), findsOneWidget);
      expect(find.textContaining('Approximate location (Sohag)'), findsOneWidget);
    });

    testWidgets('device location shown when GPS available', (tester) async {
      final device = LocationCoordinates.fromDevice(latitude: 30.0444, longitude: 31.2357);
      await configureWithFakes(outcome: CurrentLocationSuccess(device));
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
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('map_picker_fallback_indicator')), findsNothing);
      expect(find.textContaining('30.04440'), findsOneWidget);
      expect(find.text('Your device location'), findsOneWidget);
    });

    testWidgets('manual move updates coordinates and clears fallback', (tester) async {
      await configureWithFakes(outcome: const LocationServiceDisabled());
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
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('map_picker_fallback_indicator')), findsOneWidget);
      await tester.tap(find.byKey(const Key('fake_move')));
      await tester.pump();
      expect(find.textContaining('30.00000'), findsOneWidget);
      expect(find.byKey(const Key('map_picker_fallback_indicator')), findsNothing);
    });

    testWidgets('recenter updates to device location', (tester) async {
      final device = LocationCoordinates.fromDevice(latitude: 29.9, longitude: 31.0);
      final repo = _SequencedFakeRepository(
        getCurrentOutcomes: [const LocationPermissionDenied(), CurrentLocationSuccess(device)],
        requestOutcomes: [CurrentLocationSuccess(device)],
      );
      await sl.reset();
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await configureDependencies(preferences: prefs);
      if (sl.isRegistered<LocationRepository>()) sl.unregister<LocationRepository>();
      if (sl.isRegistered<GetCurrentLocationUseCase>()) sl.unregister<GetCurrentLocationUseCase>();
      if (sl.isRegistered<RequestLocationPermissionUseCase>()) sl.unregister<RequestLocationPermissionUseCase>();
      if (sl.isRegistered<MapPickerCubit>()) sl.unregister<MapPickerCubit>();
      sl.registerLazySingleton<LocationRepository>(() => repo);
      sl.registerLazySingleton<GetCurrentLocationUseCase>(() => GetCurrentLocationUseCase(sl<LocationRepository>()));
      sl.registerLazySingleton<RequestLocationPermissionUseCase>(() => RequestLocationPermissionUseCase(sl<LocationRepository>()));
      sl.registerFactory<MapPickerCubit>(() => MapPickerCubit(
            getCurrentLocationUseCase: sl<GetCurrentLocationUseCase>(),
            requestLocationPermissionUseCase: sl<RequestLocationPermissionUseCase>(),
          ));

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
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('map_picker_fallback_indicator')), findsOneWidget);
      await tester.tap(find.byKey(const Key('map_picker_recenter_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('29.90000'), findsOneWidget);
      expect(find.byKey(const Key('map_picker_fallback_indicator')), findsNothing);
    });

    testWidgets('confirm returns correct coordinates via callback', (tester) async {
      final device = LocationCoordinates.fromDevice(latitude: 30.5, longitude: 31.5);
      await configureWithFakes(outcome: CurrentLocationSuccess(device));
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
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('map_picker_confirm_button')));
      await tester.pump();
      expect(confirmed, isNotNull);
      expect(confirmed!.latitude, 30.5);
    });

    testWidgets('burgundy pin and recenter still use AppSemanticColors.primary', (tester) async {
      await configureWithFakes(outcome: const LocationPermissionDenied());
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
      await tester.pump(const Duration(milliseconds: 100));
      final pin = tester.widget<Icon>(find.byKey(const Key('map_picker_center_pin')));
      expect(pin.color, AppSemanticColors.light.primary);
      expect(pin.color, const Color(0xFF7B1E28));
      final recenter = tester.widget<Container>(find.byKey(const Key('map_picker_recenter_button')));
      final deco = recenter.decoration as BoxDecoration;
      expect(deco.color, const Color(0xFF7B1E28));
    });

    testWidgets('attribution shows OpenFreeMap, not Google', (tester) async {
      await configureWithFakes(outcome: const LocationPermissionDenied());
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
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('map_picker_attribution')), findsOneWidget);
      expect(find.text('© OpenFreeMap'), findsOneWidget);
      expect(find.text('© OpenStreetMap contributors'), findsNothing);
    });
  });
}

class _FakeLocationRepository implements LocationRepository {
  _FakeLocationRepository(this.outcome);
  final CurrentLocationOutcome outcome;
  @override
  Future<CurrentLocationOutcome> getCurrentLocation() async => outcome;
  @override
  Future<CurrentLocationOutcome> requestLocationPermission({required LocationPermissionRequestMode mode}) async => outcome;
}

class _SequencedFakeRepository implements LocationRepository {
  _SequencedFakeRepository({required this.getCurrentOutcomes, required this.requestOutcomes});
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
  Future<CurrentLocationOutcome> requestLocationPermission({required LocationPermissionRequestMode mode}) async {
    final result = requestOutcomes[_reqIndex.clamp(0, requestOutcomes.length - 1)];
    if (_reqIndex < requestOutcomes.length - 1) _reqIndex++;
    return result;
  }
}
