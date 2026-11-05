import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/routing/app_router.dart';
import 'package:luqma_app/core/routing/app_routes.dart';
import 'package:luqma_app/features/address/domain/entities/address.dart';
import 'package:luqma_app/features/address/domain/entities/address_label.dart';
import 'package:luqma_app/features/address/domain/repositories/address_repository.dart';
import 'package:luqma_app/features/address/domain/usecases/get_my_addresses_use_case.dart';
import 'package:luqma_app/features/address/presentation/cubit/address_setup_cubit.dart';
import 'package:luqma_app/features/home/presentation/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Proves `/home` is now gated by the address check (Step 2). With a
/// populated address list the gate resolves to the real home screen; otherwise
/// it shows the address setup flow. This keeps the test aligned with the
/// production routing without requiring live network access.
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    await configureDependencies(preferences: preferences);
  });

  test('maps the route name to a material page', () {
    final route = AppRouter.onGenerateRoute(
      const RouteSettings(name: AppRoutes.home),
    );

    expect(route, isA<MaterialPageRoute<void>>());
    expect(route.settings.name, AppRoutes.home);
  });

  testWidgets('builds the real home page when addresses exist', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Inject a fake address repository that returns a populated list so the
    // address gate can immediately resolve to Home instead of staying on its
    // loading indicator or requiring network access.
    if (sl.isRegistered<AddressRepository>()) {
      sl.unregister<AddressRepository>();
    }
    if (sl.isRegistered<GetMyAddressesUseCase>()) {
      sl.unregister<GetMyAddressesUseCase>();
    }
    sl.registerLazySingleton<AddressRepository>(
      () => _FakeAddressRepository(),
    );
    sl.registerLazySingleton<GetMyAddressesUseCase>(
      () => GetMyAddressesUseCase(sl<AddressRepository>()),
    );
    if (sl.isRegistered<AddressSetupCubit>()) {
      sl.unregister<AddressSetupCubit>();
    }
    sl.registerFactory<AddressSetupCubit>(
      () => AddressSetupCubit(
        getMyAddressesUseCase: sl<GetMyAddressesUseCase>(),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRoutes.login,
      ),
    );

    final context = tester.element(find.byType(Navigator));
    AppRouter.pushNamed<void>(context, AppRoutes.home);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(HomePage), findsOneWidget);
  });
}

class _FakeAddressRepository implements AddressRepository {
  @override
  Future<void> createAddress(address) async {}

  @override
  Future<List<Address>> getMyAddresses() async {
    return const [
      Address(
        id: '1',
        label: AddressLabel.home,
        title: 'Home',
        district: 'District',
        city: 'Sohag',
        details: 'Building 1',
        latitude: 26.56,
        longitude: 31.69,
        isDefault: true,
      ),
    ];
  }
}
