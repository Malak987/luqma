import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/presentation/cubit/app_settings_cubit.dart';
import 'package:luqma_app/core/routing/app_router.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/address/domain/entities/address.dart';
import 'package:luqma_app/features/address/domain/entities/address_draft.dart';
import 'package:luqma_app/features/address/domain/entities/address_label.dart';
import 'package:luqma_app/features/address/domain/repositories/address_repository.dart';
import 'package:luqma_app/features/address/domain/usecases/get_my_addresses_use_case.dart';
import 'package:luqma_app/features/address/presentation/cubit/address_setup_cubit.dart';
import 'package:luqma_app/features/address/presentation/pages/address_gate.dart';
import 'package:luqma_app/features/shell/presentation/pages/main_shell_page.dart';
import 'package:luqma_app/features/location/domain/entities/location_coordinates.dart';
import 'package:luqma_app/features/home/domain/repositories/main_category_repository.dart';
import '../../../home/support/main_category_fixtures.dart';

const address = Address(
    id: 'home-1',
    label: AddressLabel.home,
    title: 'My flat',
    district: 'District',
    city: 'Sohag',
    details: 'Flat 3',
    latitude: 26.56,
    longitude: 31.69,
    isDefault: true);

class AddressRepo implements AddressRepository {
  final pending = Completer<List<Address>>();
  int calls = 0;
  @override
  Future<List<Address>> getMyAddresses() =>
      ++calls == 1 ? Future.value([address]) : pending.future;
  @override
  Future<void> createAddress(AddressDraft address) async {}
  @override
  Future<Address> updateAddress(
          {required String id, required AddressDraft address}) =>
      throw UnimplementedError();
}

void main() {
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final dark in [false, true]) {
      testWidgets(
          'address refresh preserves shell and sheet $locale dark=$dark',
          (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        SharedPreferences.setMockInitialValues({});
        final repo = AddressRepo();
        sl.registerLazySingleton<MainCategoryRepository>(
            FakeMainCategoryRepository.new);
        sl.registerSingleton<AddressRepository>(repo);
        await configureDependencies(
            preferences: await SharedPreferences.getInstance());
        addTearDown(() async => sl.reset());
        await tester.binding.setSurfaceSize(const Size(800, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(BlocProvider<AppSettingsCubit>.value(
            value: sl<AppSettingsCubit>(),
            child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: locale,
              onGenerateRoute: AppRouter.onGenerateRoute,
              home: AuthenticatedAddressGate(),
            )));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(MainShellPage), findsOneWidget);
        await tester.tap(find.byKey(const Key('home_app_bar_address')));
        await tester.pump(const Duration(milliseconds: 400));
        expect(
            find.byKey(const Key('address_populated_state')), findsOneWidget);
        final shellContext = tester.element(find.byType(MainShellPage));
        final cubit = shellContext.read<AddressSetupCubit>();
        final navFinder = find.byWidgetPredicate((w) =>
            w is Navigator &&
            w.key is GlobalKey<NavigatorState> &&
            (w.key as GlobalKey<NavigatorState>)
                .toString()
                .contains('shell_home'));
        final before = tester.state<NavigatorState>(navFinder);
        final refresh = cubit.load();
        await tester.pump();
        expect(find.byType(MainShellPage), findsOneWidget,
            reason: 'a refresh must not tear down the shell or its open route');
        expect(tester.state<NavigatorState>(navFinder), same(before));
        repo.pending.complete([address]);
        await refresh;
        await tester.pump(const Duration(milliseconds: 400));
        expect(
            find.byKey(const Key('address_populated_state')), findsOneWidget);
        // Edit is the same form reached through an inner route over the sheet.
        await tester.tap(find.byKey(const Key('address_edit_home-1')));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byKey(const Key('address_details_page')), findsOneWidget);
        expect(find.byKey(const Key('address_details_change_location')),
            findsOneWidget);
        final editField = tester.widget<TextField>(find.descendant(
            of: find.byKey(const Key('address_details_title_field')),
            matching: find.byType(TextField)));
        expect(editField.controller?.text, address.title);
        await tester
            .tap(find.byKey(const Key('address_details_change_location')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final rootNavigator =
            tester.state<NavigatorState>(find.byType(Navigator).first);
        rootNavigator.pop(LocationCoordinates.fromMapSelection(
            latitude: 27.0, longitude: 31.0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.textContaining('27.00000'), findsOneWidget);
        final stillPrefilled = tester.widget<TextField>(find.descendant(
            of: find.byKey(const Key('address_details_title_field')),
            matching: find.byType(TextField)));
        expect(stillPrefilled.controller?.text, address.title);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.tap(find.byKey(const Key('nav_account')));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.byKey(const Key('nav_home')));
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byKey(const Key('address_details_page')), findsOneWidget);
        expect(find.byKey(const Key('address_details_change_location')),
            findsOneWidget);
        for (final key in [
          'address_details_title_field',
          'address_details_district_field',
          'address_details_city_field',
          'address_details_details_field',
          'address_details_submit'
        ]) {
          expect(find.byKey(Key(key)), findsOneWidget);
        }
        expect(tester.state<NavigatorState>(navFinder), same(before));
        before.pop();
        await tester.pump(const Duration(milliseconds: 400));
        expect(
            find.byKey(const Key('address_populated_state')), findsOneWidget);
        await tester.tap(find.byKey(const Key('address_add_button_populated')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        // Simulate confirming the actual map route; its result immediately
        // drives the next route while the map's reverse animation is active.
        before.pop(LocationCoordinates.fromMapSelection(
            latitude: 26.56, longitude: 31.69));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byKey(const Key('address_details_page')), findsOneWidget);
        expect(find.byKey(const Key('address_details_change_location')),
            findsOneWidget);
        for (final key in [
          'address_details_title_field',
          'address_details_district_field',
          'address_details_city_field',
          'address_details_details_field',
          'address_details_submit'
        ]) {
          expect(find.byKey(Key(key)), findsOneWidget);
        }
        expect(tester.state<NavigatorState>(navFinder), same(before));
        before.pop();
        await tester.pump(const Duration(milliseconds: 400));
        expect(
            find.byKey(const Key('address_populated_state')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
