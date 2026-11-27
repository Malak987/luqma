import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/address/domain/entities/address.dart';
import 'package:luqma_app/features/address/domain/entities/address_label.dart';
import 'package:luqma_app/features/address/domain/usecases/get_my_addresses_use_case.dart';
import 'package:luqma_app/features/address/presentation/cubit/address_setup_cubit.dart';
import 'package:luqma_app/features/address/presentation/widgets/address_manager_sheet.dart';

void main() {
  const home = Address(
    id: 'home-1',
    label: AddressLabel.home,
    // The label chip already renders "Home", so the title must differ for the
    // test to tell the two texts apart.
    title: 'My flat',
    district: 'Minya',
    city: 'El Minya',
    details: 'Flat 3',
    latitude: 28.1,
    longitude: 30.75,
    isDefault: true,
  );
  const work = Address(
    id: 'work-1',
    label: AddressLabel.work,
    title: 'Office',
    district: 'Downtown',
    city: 'El Minya',
    details: 'Floor 2',
    latitude: 28.11,
    longitude: 30.76,
    isDefault: false,
  );

  Future<AddressSetupCubit> pumpHost(
    WidgetTester tester, {
    List<Address> addresses = const <Address>[home, work],
    Locale locale = const Locale('en'),
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final cubit = AddressSetupCubit(
      getMyAddressesUseCase: _FakeGetMyAddresses(addresses),
    );
    addTearDown(cubit.close);
    await cubit.load();

    await tester.pumpWidget(
      BlocProvider<AddressSetupCubit>.value(
        value: cubit,
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  key: const Key('open_address_sheet'),
                  onPressed: () => showAddressManagerSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return cubit;
  }

  testWidgets('lists the saved addresses and marks the one in use',
      (tester) async {
    await pumpHost(tester);

    await tester.tap(find.byKey(const Key('open_address_sheet')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('address_populated_state')), findsOneWidget);
    expect(find.byKey(const Key('address_tile_home-1')), findsOneWidget);
    expect(find.byKey(const Key('address_tile_work-1')), findsOneWidget);
    expect(find.text('My flat'), findsOneWidget);
    expect(find.text('Office'), findsOneWidget);
    // The chips use the localized label, not the free-text title.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.byKey(const Key('address_add_button_populated')), findsOneWidget);
    expect(find.byKey(const Key('address_edit_work-1')), findsOneWidget);
  });

  testWidgets('selecting an address updates the cubit and closes the sheet',
      (tester) async {
    final cubit = await pumpHost(tester);

    await tester.tap(find.byKey(const Key('open_address_sheet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('address_tile_work-1')));
    await tester.pumpAndSettle();

    expect(cubit.state.selectedAddress?.id, 'work-1');
    // The sheet is dismissed once an address is chosen.
    expect(find.byKey(const Key('address_populated_state')), findsNothing);
  });

  testWidgets('shows the empty state with an add action', (tester) async {
    await pumpHost(tester, addresses: const <Address>[]);

    await tester.tap(find.byKey(const Key('open_address_sheet')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('address_manager_empty')), findsOneWidget);
    expect(find.byKey(const Key('address_manager_add_empty')), findsOneWidget);
  });

  testWidgets('renders in Arabic RTL without overflow', (tester) async {
    await pumpHost(tester, locale: const Locale('ar'));

    await tester.tap(find.byKey(const Key('open_address_sheet')));
    await tester.pumpAndSettle();

    expect(find.text('عنوان التوصيل'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeGetMyAddresses implements GetMyAddressesUseCase {
  _FakeGetMyAddresses(this.addresses);

  final List<Address> addresses;

  @override
  Future<List<Address>> call() async => addresses;
}
