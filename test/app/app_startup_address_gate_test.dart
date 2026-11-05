import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/app/app.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/core/presentation/cubit/app_settings_cubit.dart';
import 'package:luqma_app/core/storage/preferences_storage_service.dart';
import 'package:luqma_app/features/address/domain/entities/address.dart';
import 'package:luqma_app/features/address/domain/entities/address_label.dart';
import 'package:luqma_app/features/address/domain/repositories/address_repository.dart';
import 'package:luqma_app/features/address/domain/usecases/get_my_addresses_use_case.dart';
import 'package:luqma_app/features/address/presentation/cubit/address_setup_cubit.dart';
import 'package:luqma_app/features/address/presentation/pages/address_setup_page.dart';
import 'package:luqma_app/features/authentication/login/presentation/pages/login_page.dart';
import 'package:luqma_app/features/authentication/presentation/cubit/auth_session_cubit.dart';
import 'package:luqma_app/features/home/presentation/pages/home_page.dart';
import 'package:luqma_app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:luqma_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:luqma_app/features/splash/presentation/pages/splash_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> setupBase({bool hasCompletedOnboarding = true}) async {
    await sl.reset();
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({
      PreferencesStorageService.hasCompletedOnboardingKey: hasCompletedOnboarding,
    });
    final prefs = await SharedPreferences.getInstance();
    await configureDependencies(preferences: prefs);
  }

  Future<void> setAuthenticated({bool expired = false}) async {
    final expiresAt = expired
        ? DateTime.now().toUtc().subtract(const Duration(days: 1)).toIso8601String()
        : DateTime.now().toUtc().add(const Duration(days: 30)).toIso8601String();
    FlutterSecureStorage.setMockInitialValues({
      'auth_session_v1':
          '{"token":"test-token","userId":"u1","userName":"Test","role":"user","expiresAt":"$expiresAt"}',
    });
    // Re-configure to pick up new storage values
    // AuthSessionCubit will read this on checkSession()
  }

  Future<void> injectAddressRepo(Future<List<Address>> Function() getMyAddresses) async {
    if (sl.isRegistered<AddressRepository>()) sl.unregister<AddressRepository>();
    if (sl.isRegistered<GetMyAddressesUseCase>()) sl.unregister<GetMyAddressesUseCase>();
    if (sl.isRegistered<AddressSetupCubit>()) sl.unregister<AddressSetupCubit>();

    sl.registerLazySingleton<AddressRepository>(() => _FakeAddressRepository(getMyAddresses));
    sl.registerLazySingleton<GetMyAddressesUseCase>(
      () => GetMyAddressesUseCase(sl<AddressRepository>()),
    );
    sl.registerFactory<AddressSetupCubit>(
      () => AddressSetupCubit(getMyAddressesUseCase: sl<GetMyAddressesUseCase>()),
    );
  }

  Widget buildApp() {
    final settingsCubit = sl<AppSettingsCubit>();
    final authCubit = sl<AuthSessionCubit>();
    final onboardingCubit = sl<OnboardingCubit>();
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
        BlocProvider<AuthSessionCubit>.value(value: authCubit),
        BlocProvider<OnboardingCubit>.value(value: onboardingCubit),
      ],
      child: const LuqmaApp(),
    );
  }

  tearDown(() async => sl.reset());

  group('App Startup → Address Gate', () {
    testWidgets('Scenario A: authenticated with no addresses shows Address Setup empty', (tester) async {
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await setupBase(hasCompletedOnboarding: true);
      await setAuthenticated();
      // Re-init with new secure storage mock
      final prefs = await SharedPreferences.getInstance();
      await sl.reset();
      SharedPreferences.setMockInitialValues({
        PreferencesStorageService.hasCompletedOnboardingKey: true,
      });
      FlutterSecureStorage.setMockInitialValues({
        'auth_session_v1':
            '{"token":"t","userId":"u1","userName":"Test","role":"user","expiresAt":"${DateTime.now().toUtc().add(const Duration(days: 30)).toIso8601String()}"}',
      });
      await configureDependencies(preferences: prefs);
      await injectAddressRepo(() async => []);

      await tester.pumpWidget(buildApp());
      expect(find.byType(SplashPage), findsOneWidget);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      // After splash, should be loading then empty
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('address_setup_page')), findsOneWidget);
      expect(find.byKey(const Key('address_empty_state')), findsOneWidget);
    });

    testWidgets('Scenario B: authenticated with existing address goes to Home', (tester) async {
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await setupBase(hasCompletedOnboarding: true);
      FlutterSecureStorage.setMockInitialValues({
        'auth_session_v1':
            '{"token":"t","userId":"u1","userName":"Test","role":"user","expiresAt":"${DateTime.now().toUtc().add(const Duration(days: 30)).toIso8601String()}"}',
      });
      final prefs = await SharedPreferences.getInstance();
      await sl.reset();
      SharedPreferences.setMockInitialValues({
        PreferencesStorageService.hasCompletedOnboardingKey: true,
      });
      await configureDependencies(preferences: prefs);
      await injectAddressRepo(() async => [
            const Address(
              id: '1',
              label: AddressLabel.home,
              title: 'Home',
              district: 'D',
              city: 'Sohag',
              details: 'Det',
              latitude: 26.5,
              longitude: 31.6,
              isDefault: true,
            )
          ]);

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byKey(const Key('address_empty_state')), findsNothing);
    });

    testWidgets('Scenario C: address API failure shows error not empty', (tester) async {
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await setupBase(hasCompletedOnboarding: true);
      FlutterSecureStorage.setMockInitialValues({
        'auth_session_v1':
            '{"token":"t","userId":"u1","userName":"Test","role":"user","expiresAt":"${DateTime.now().toUtc().add(const Duration(days: 30)).toIso8601String()}"}',
      });
      final prefs = await SharedPreferences.getInstance();
      await sl.reset();
      SharedPreferences.setMockInitialValues({
        PreferencesStorageService.hasCompletedOnboardingKey: true,
      });
      await configureDependencies(preferences: prefs);
      await injectAddressRepo(() async => throw Exception('network fail'));

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('address_error_state')), findsOneWidget);
      expect(find.byKey(const Key('address_empty_state')), findsNothing);
    });

    testWidgets('Scenario D: unauthenticated shows Login', (tester) async {
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await setupBase(hasCompletedOnboarding: true);
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await sl.reset();
      SharedPreferences.setMockInitialValues({
        PreferencesStorageService.hasCompletedOnboardingKey: true,
      });
      await configureDependencies(preferences: prefs);
      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    });

    testWidgets('onboarding incomplete shows OnboardingPage before auth', (tester) async {
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await setupBase(hasCompletedOnboarding: false);
      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(OnboardingPage), findsOneWidget);
    });
  });
}

class _FakeAddressRepository implements AddressRepository {
  _FakeAddressRepository(this._getMyAddresses);
  final Future<List<Address>> Function() _getMyAddresses;
  @override
  Future<List<Address>> getMyAddresses() => _getMyAddresses();
  @override
  Future<void> createAddress(address) async {}
}
