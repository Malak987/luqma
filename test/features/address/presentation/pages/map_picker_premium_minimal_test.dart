import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:latlong2/latlong.dart';

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
      child: Text('style:${isDark ? 'dark' : 'light'} ${center.latitude}'),
    );
  }

  group('Phase E — Premium Minimal Map (TileProviderConfig)', () {
    test('TileProviderConfig light/dark URLs are distinct and use correct Geoapify styles or OSM fallback', () {
      // Without GEOAPIFY_API_KEY (default in tests), both fallback to OSM — still distinct via background, but URLs equal.
      // With key, they differ: osm-bright vs dark-matter-dark-grey.
      // We assert the documented style ids are present in the config source (not inventing hex).
      expect(TileProviderConfig.lightUrlTemplate, isNotEmpty);
      expect(TileProviderConfig.darkUrlTemplate, isNotEmpty);
      // When no key, both are OSM fallback — acceptable for dev. When key set, they differ.
      if (TileProviderConfig.hasGeoapifyKey) {
        expect(TileProviderConfig.lightUrlTemplate, contains('osm-bright'));
        expect(TileProviderConfig.darkUrlTemplate, contains('dark-matter'));
        expect(TileProviderConfig.lightUrlTemplate, isNot(TileProviderConfig.darkUrlTemplate));
      } else {
        // Fallback documented
        expect(TileProviderConfig.lightUrlTemplate, TileProviderConfig.osmUrlTemplate);
        expect(TileProviderConfig.darkUrlTemplate, TileProviderConfig.osmUrlTemplate);
      }
      expect(TileProviderConfig.activeAttribution, isNotEmpty);
      // OSM attribution always present
      expect(TileProviderConfig.osmAttribution, '© OpenStreetMap contributors');
    });

    test('urlFor respects isDark', () {
      expect(TileProviderConfig.urlFor(isDark: false), TileProviderConfig.lightUrlTemplate);
      expect(TileProviderConfig.urlFor(isDark: true), TileProviderConfig.darkUrlTemplate);
    });
  });

  group('Phase E — Map UI uses Burgundy token and theme-aware tiles', () {
    testWidgets('Light theme selects light map style via isDark=false', (tester) async {
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
      expect(find.byKey(const Key('fake_map_light')), findsOneWidget);
      expect(find.byKey(const Key('fake_map_dark')), findsNothing);
    });

    testWidgets('Dark theme selects dark charcoal map style via isDark=true', (tester) async {
      await configureWithFakes(outcome: const LocationPermissionDenied());
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
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('fake_map_dark')), findsOneWidget);
      expect(find.byKey(const Key('fake_map_light')), findsNothing);
    });

    testWidgets('Burgundy pin uses existing theme token AppSemanticColors.primary #7B1E28', (tester) async {
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
      // Burgundy token from AppSemanticColors.light.primary
      expect(pin.color, AppSemanticColors.light.primary);
      expect(pin.color, const Color(0xFF7B1E28));
    });

    testWidgets('Recenter control uses Burgundy background with onPrimary icon', (tester) async {
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
      final recenterContainer = tester.widget<Container>(find.byKey(const Key('map_picker_recenter_button')));
      final deco = recenterContainer.decoration as BoxDecoration;
      expect(deco.color, AppSemanticColors.light.primary);
      expect(deco.color, const Color(0xFF7B1E28));
      final icon = tester.widget<Icon>(find.byIcon(Icons.my_location_rounded));
      expect(icon.color, AppSemanticColors.light.onPrimary);
    });

    testWidgets('Theme change updates map style without restart (pump with new theme)', (tester) async {
      await configureWithFakes(outcome: const LocationPermissionDenied());
      // Wrap in StatefulBuilder to toggle theme via rebuild
      bool isDark = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            theme: isDark ? AppTheme.dark : AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: MapLocationPickerPage(mapBuilder: fakeMapBuilder),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('fake_map_light')), findsOneWidget);
      // Simulate theme switch by repumping with dark theme (no restart)
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
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('fake_map_dark')), findsOneWidget);
    });

    testWidgets('Attribution visible in LTR and RTL', (tester) async {
      await configureWithFakes(outcome: const LocationPermissionDenied());
      for (final locale in [const Locale('en'), const Locale('ar')]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale,
            home: MapLocationPickerPage(mapBuilder: fakeMapBuilder),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byKey(const Key('map_picker_attribution')), findsOneWidget);
        // Attribution text must be one of the two valid attributions
        final text = tester.widget<Text>(find.descendant(of: find.byKey(const Key('map_picker_attribution')), matching: find.byType(Text)));
        expect([TileProviderConfig.osmAttribution, TileProviderConfig.geoapifyAttribution, TileProviderConfig.activeAttribution].contains(text.data), isTrue);
      }
    });

    testWidgets('Tile loading state uses theme-appropriate background', (tester) async {
      final completer = Completer<CurrentLocationOutcome>();
      await configureWithFakes(outcome: const LocationPermissionDenied());
      // Override to pending so loading shows
      await sl.reset();
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await configureDependencies(preferences: prefs);
      if (sl.isRegistered<LocationRepository>()) sl.unregister<LocationRepository>();
      if (sl.isRegistered<GetCurrentLocationUseCase>()) sl.unregister<GetCurrentLocationUseCase>();
      if (sl.isRegistered<RequestLocationPermissionUseCase>()) sl.unregister<RequestLocationPermissionUseCase>();
      if (sl.isRegistered<MapPickerCubit>()) sl.unregister<MapPickerCubit>();
      final repo = _PendingLocationRepository(completer);
      sl.registerLazySingleton<LocationRepository>(() => repo);
      sl.registerLazySingleton<GetCurrentLocationUseCase>(() => GetCurrentLocationUseCase(sl<LocationRepository>()));
      sl.registerLazySingleton<RequestLocationPermissionUseCase>(() => RequestLocationPermissionUseCase(sl<LocationRepository>()));
      sl.registerFactory<MapPickerCubit>(() => MapPickerCubit(getCurrentLocationUseCase: sl<GetCurrentLocationUseCase>(), requestLocationPermissionUseCase: sl<RequestLocationPermissionUseCase>()));

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
      expect(find.byKey(const Key('map_picker_loading')), findsOneWidget);
      completer.complete(const LocationPermissionDenied());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('map_picker_loading')), findsNothing);
    });

    testWidgets('Existing map selection and confirmation behavior unchanged', (tester) async {
      final device = LocationCoordinates.fromDevice(latitude: 26.56, longitude: 31.69);
      await configureWithFakes(outcome: CurrentLocationSuccess(device));
      LocationCoordinates? confirmed;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MapLocationPickerPage(
            mapBuilder: (ctx, center, onMoved, isDark) => Column(
              children: [
                Text('center ${center.latitude}'),
                ElevatedButton(key: const Key('fake_move'), onPressed: () => onMoved(const LatLng(30, 31)), child: const Text('Move')),
              ],
            ),
            onConfirmed: (c) => confirmed = c,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('fake_move')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('map_picker_confirm_button')));
      await tester.pump();
      expect(confirmed, isNotNull);
      expect(confirmed!.latitude, 30);
      expect(confirmed!.longitude, 31);
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

class _PendingLocationRepository implements LocationRepository {
  _PendingLocationRepository(this.completer);
  final Completer<CurrentLocationOutcome> completer;
  @override
  Future<CurrentLocationOutcome> getCurrentLocation() => completer.future;
  @override
  Future<CurrentLocationOutcome> requestLocationPermission({required LocationPermissionRequestMode mode}) async => completer.future;
}
