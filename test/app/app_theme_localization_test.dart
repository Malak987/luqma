import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/app/app.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/core/presentation/cubit/app_settings_cubit.dart';
import 'package:luqma_app/features/authentication/presentation/cubit/auth_session_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    await configureDependencies(preferences: prefs);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('LuqmaApp updates theme and locale live without restart',
      (tester) async {
    final settingsCubit = sl<AppSettingsCubit>();
    final authSessionCubit = sl<AuthSessionCubit>();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
          BlocProvider<AuthSessionCubit>.value(value: authSessionCubit),
        ],
        child: const LuqmaApp(),
      ),
    );
    await tester.pump();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, equals(ThemeMode.system));
    expect(materialApp.locale, equals(const Locale('ar')));
    expect(
      materialApp.themeAnimationDuration,
      equals(const Duration(milliseconds: 300)),
    );

    // Live update theme mode
    await settingsCubit.setThemeMode(ThemeMode.light);
    await tester.pump();

    final updatedAppLight =
        tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(updatedAppLight.themeMode, equals(ThemeMode.light));

    // Live update locale
    await settingsCubit.setLocale(const Locale('en'));
    await tester.pump();

    final updatedAppEn = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(updatedAppEn.locale, equals(const Locale('en')));
  });

  testWidgets(
      'LuqmaApp responds dynamically to runtime changes in Reduce Motion',
      (tester) async {
    final settingsCubit = sl<AppSettingsCubit>();
    final authSessionCubit = sl<AuthSessionCubit>();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
          BlocProvider<AuthSessionCubit>.value(value: authSessionCubit),
        ],
        child: const LuqmaApp(),
      ),
    );
    await tester.pump();

    // 1. Initial state: Reduce Motion (disableAnimations) is false -> 300ms transition
    var materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      materialApp.themeAnimationDuration,
      equals(const Duration(milliseconds: 300)),
    );

    // 2. Enable Reduce Motion dynamically at runtime
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    tester.binding.handleAccessibilityFeaturesChanged();
    await tester.pump();

    materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeAnimationDuration, equals(Duration.zero));

    // 3. Disable Reduce Motion dynamically at runtime
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: false);
    tester.binding.handleAccessibilityFeaturesChanged();
    await tester.pump();

    materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      materialApp.themeAnimationDuration,
      equals(const Duration(milliseconds: 300)),
    );
  });

  testWidgets(
      'LuqmaApp removes WidgetsBindingObserver on dispose without leaking',
      (tester) async {
    final settingsCubit = sl<AppSettingsCubit>();
    final authSessionCubit = sl<AuthSessionCubit>();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
          BlocProvider<AuthSessionCubit>.value(value: authSessionCubit),
        ],
        child: const LuqmaApp(),
      ),
    );
    await tester.pump();

    // Unmount LuqmaApp to trigger dispose()
    await tester.pumpWidget(const SizedBox.shrink());

    // Trigger accessibility feature change after dispose
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    tester.binding.handleAccessibilityFeaturesChanged();
    await tester.pump();

    expect(find.byType(LuqmaApp), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
