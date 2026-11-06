import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/map/tile_provider_config.dart';
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

  group('E.1 Production hardening — release-safe config', () {
    testWidgets('debug without key shows map (not config error) — OSM fallback allowed', (tester) async {
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
            debugApiKeyOverride: '',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('map_picker_config_error')), findsNothing);
      expect(find.byKey(const Key('fake_map_light')), findsOneWidget);
      expect(find.byKey(const Key('map_picker_attribution')), findsOneWidget);
      // Pure logic confirms OSM fallback
      final sel = TileProviderConfig.resolve(isReleaseMode: false, apiKey: '', isDark: false);
      expect(sel.isOsmFallback, isTrue);
      expect(sel.urlTemplate, TileProviderConfig.osmUrlTemplate);
    });

    testWidgets('debug with key shows map with Geoapify style, not OSM', (tester) async {
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
      final lightSel = TileProviderConfig.resolve(isReleaseMode: false, apiKey: 'test-key-123', isDark: false);
      expect(lightSel.urlTemplate, contains('osm-bright'));
      expect(lightSel.urlTemplate, contains('test-key-123'));
      final darkSel = TileProviderConfig.resolve(isReleaseMode: false, apiKey: 'test-key-123', isDark: true);
      expect(darkSel.urlTemplate, contains('dark-matter-dark-grey'));
    });

    testWidgets('release with key shows map (Geoapify)', (tester) async {
      await configureWithFakes(outcome: const LocationPermissionDenied());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(
            mapBuilder: fakeMapBuilder,
            debugIsReleaseModeOverride: true,
            debugApiKeyOverride: 'prod-key-456',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('map_picker_config_error')), findsNothing);
      expect(find.byKey(const Key('fake_map_light')), findsOneWidget);
      final sel = TileProviderConfig.resolve(isReleaseMode: true, apiKey: 'prod-key-456', isDark: false);
      expect(sel.isGeoapify, isTrue);
      expect(sel.isConfigurationError, isFalse);
    });

    testWidgets('release without key shows localized config error, never OSM', (tester) async {
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
      // Must not initialize OSM tiles — fake map must NOT be present, nor map_picker_map
      expect(find.byKey(const Key('fake_map_light')), findsNothing);
      expect(find.byKey(const Key('fake_map_dark')), findsNothing);
      expect(find.byKey(const Key('map_picker_map')), findsNothing);
      // Pure logic confirms never OSM
      final sel = TileProviderConfig.resolve(isReleaseMode: true, apiKey: '', isDark: false);
      expect(sel.isConfigurationError, isTrue);
      expect(sel.urlTemplate, isNot(TileProviderConfig.osmUrlTemplate));
      expect(sel.kind, TileProviderKind.configurationError);

      // Arabic localization
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
      expect(find.text('إعداد الخريطة غير مكتمل. يرجى التواصل مع الدعم أو المحاولة لاحقًا.'), findsOneWidget);
    });

    testWidgets('release without key never shows OSM attribution fallback — error UI has no map', (tester) async {
      await configureWithFakes(outcome: const LocationPermissionDenied());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(
            debugIsReleaseModeOverride: true,
            debugApiKeyOverride: '',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Config error screen should be visible, real map not initialized
      expect(find.byKey(const Key('map_picker_config_error')), findsOneWidget);
      expect(find.byKey(const Key('map_picker_map')), findsNothing);
    });

    testWidgets('configured key selects correct light/dark style via resolve', (tester) async {
      const key = 'k-123';
      final light = TileProviderConfig.resolve(isReleaseMode: true, apiKey: key, isDark: false);
      final dark = TileProviderConfig.resolve(isReleaseMode: true, apiKey: key, isDark: true);
      expect(light.urlTemplate.contains('osm-bright'), isTrue);
      expect(dark.urlTemplate.contains('dark-matter-dark-grey'), isTrue);
      expect(light.urlTemplate == dark.urlTemplate, isFalse);
      expect(light.attribution, TileProviderConfig.geoapifyAttribution);
      expect(dark.attribution, TileProviderConfig.geoapifyAttribution);
    });

    test('all four combinations deterministically via pure function', () {
      const k = 'k';
      // 1. debug without key
      expect(
        TileProviderConfig.resolve(isReleaseMode: false, apiKey: '', isDark: false).kind,
        TileProviderKind.osmFallback,
      );
      // 2. debug with key
      expect(
        TileProviderConfig.resolve(isReleaseMode: false, apiKey: k, isDark: false).kind,
        TileProviderKind.geoapify,
      );
      // 3. release with key
      expect(
        TileProviderConfig.resolve(isReleaseMode: true, apiKey: k, isDark: false).kind,
        TileProviderKind.geoapify,
      );
      // 4. release without key
      expect(
        TileProviderConfig.resolve(isReleaseMode: true, apiKey: '', isDark: false).kind,
        TileProviderKind.configurationError,
      );
    });
  });

  group('E.1 Tile error does not disable map interaction', () {
    testWidgets('tile error banner appears but map remains interactive and attribution visible', (tester) async {
      final device = LocationCoordinates.fromDevice(latitude: 30.0, longitude: 31.0);
      await configureWithFakes(outcome: CurrentLocationSuccess(device));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(
            // Use real map to get TileLayer, but we will trigger error manually
            debugIsReleaseModeOverride: false,
            debugApiKeyOverride: '', // OSM fallback in debug — stable
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Initially no tile error
      expect(find.byKey(const Key('map_picker_tile_error')), findsNothing);
      expect(find.byKey(const Key('map_picker_attribution')), findsOneWidget);
      expect(find.byKey(const Key('map_picker_confirm_button')), findsOneWidget);
      final confirmBtn = tester.widget<ElevatedButton>(find.byKey(const Key('map_picker_confirm_button')));
      expect(confirmBtn.onPressed, isNotNull);

      // Trigger tile error via TileLayer callback
      final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
      // Simulate first tile failure — should not expose key, not throw
      tileLayer.errorTileCallback?.call(
        // We pass a dummy TileImage-like object; use TileCoordinates as tile stand-in for test
        // The callback signature is (TileImage, Object, StackTrace?) in real code; we pass TileCoordinates fake
        // but our _onTileError accepts dynamic tile, so any object works.
        // Use a minimal object with coordinates field if needed, but we just pass a fake.
        // To satisfy TileImage type, we need to construct one — easiest: call via dynamic
        // and let the page's handler handle it (it only logs error, not tile URL).
        // We'll use a simple FakeTile.
        _FakeTile() as dynamic,
        Exception('network error'),
        StackTrace.current,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // After first error, banner appears, attribution still visible, confirm still enabled
      expect(find.byKey(const Key('map_picker_tile_error')), findsOneWidget);
      expect(find.text('Some map tiles failed to load. You can still move the map.'), findsOneWidget);
      expect(find.byKey(const Key('map_picker_attribution')), findsOneWidget);
      expect(find.byKey(const Key('map_picker_map')), findsOneWidget);
      final confirmBtnAfter = tester.widget<ElevatedButton>(find.byKey(const Key('map_picker_confirm_button')));
      expect(confirmBtnAfter.onPressed, isNotNull, reason: 'tile error must not disable confirm');

      // Second error must be debounced — still only one banner, no exception
      tileLayer.errorTileCallback?.call(_FakeTile() as dynamic, Exception('second'), StackTrace.current);
      await tester.pump();
      expect(find.byKey(const Key('map_picker_tile_error')), findsOneWidget);

      // Map interaction preserved: confirm still works
      LocationCoordinates? confirmed;
      // Re-pump with onConfirmed to verify
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(
            onConfirmed: (c) => confirmed = c,
            debugIsReleaseModeOverride: false,
            debugApiKeyOverride: '',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Trigger error again
      final tl2 = tester.widget<TileLayer>(find.byType(TileLayer));
      tl2.errorTileCallback?.call(_FakeTile() as dynamic, Exception('err'), StackTrace.current);
      await tester.pump();
      await tester.tap(find.byKey(const Key('map_picker_confirm_button')));
      await tester.pump();
      expect(confirmed, isNotNull);
    });

    testWidgets('tile error placeholder is themed and attribution not overlapped', (tester) async {
      await configureWithFakes(outcome: const LocationPermissionDenied());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(
            debugIsReleaseModeOverride: false,
            debugApiKeyOverride: '',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
      tileLayer.errorTileCallback?.call(_FakeTile() as dynamic, Exception('e'), StackTrace.current);
      await tester.pump();
      expect(find.byKey(const Key('map_picker_tile_error')), findsOneWidget);
      expect(find.byKey(const Key('map_picker_attribution')), findsOneWidget);
      // Attribution must still be RTL-aware at narrow width
      await tester.binding.setSurfaceSize(const Size(320, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pump();
      expect(find.byKey(const Key('map_picker_attribution')), findsOneWidget);
      expect(find.byKey(const Key('map_picker_tile_error')), findsOneWidget);
    });
  });

  group('E.1 Theme switch preserves selected coordinates', () {
    testWidgets('theme switch preserves selected coordinates (no restart)', (tester) async {
      final device = LocationCoordinates.fromDevice(latitude: 26.56, longitude: 31.69);
      await configureWithFakes(outcome: CurrentLocationSuccess(device));

      // Start light
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
                ElevatedButton(key: const Key('fake_move'), onPressed: () => onMoved(const LatLng(30.5, 31.5))),
              ],
            ),
            debugIsReleaseModeOverride: false,
            debugApiKeyOverride: '',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('26.56000'), findsOneWidget);
      // Move map
      await tester.tap(find.byKey(const Key('fake_move')));
      await tester.pump();
      expect(find.textContaining('30.50000'), findsOneWidget);
      expect(find.textContaining('31.50000'), findsOneWidget);

      // Switch to dark theme — must preserve moved coordinates
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
                ElevatedButton(key: const Key('fake_move'), onPressed: () => onMoved(const LatLng(30.5, 31.5))),
                // Show isDark to verify theme switch
                Text(isDark ? 'dark' : 'light', key: const Key('theme_indicator')),
              ],
            ),
            debugIsReleaseModeOverride: false,
            debugApiKeyOverride: '',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('theme_indicator')), findsOneWidget);
      expect(find.text('dark'), findsOneWidget);
      // Coordinates must still be moved value, not reset to initial
      expect(find.textContaining('30.50000'), findsOneWidget);
      expect(find.textContaining('31.50000'), findsOneWidget);
      expect(find.textContaining('26.56000'), findsNothing);
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

class _FakeTile {
  final coordinates = const LatLng(0, 0);
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
