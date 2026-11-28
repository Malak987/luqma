import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/presentation/cubit/app_settings_cubit.dart';
import 'package:luqma_app/core/storage/preferences_storage_service.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/account/presentation/pages/account_page.dart';

void main() {
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final dark in [false, true]) {
      testWidgets(
          'profile fits narrow screen and large text $locale dark=$dark',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        SharedPreferences.setMockInitialValues({});
        final settings = AppSettingsCubit(
            preferencesStorageService: PreferencesStorageService(
                await SharedPreferences.getInstance()));
        addTearDown(settings.close);
        await tester.pumpWidget(BlocProvider<AppSettingsCubit>.value(
            value: settings,
            child: MaterialApp(
              locale: locale,
              theme: dark ? AppTheme.dark : AppTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!),
              home: const Scaffold(body: AccountPage()),
            )));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
            find.byKey(const Key('account_logout_tile')), 300,
            scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
