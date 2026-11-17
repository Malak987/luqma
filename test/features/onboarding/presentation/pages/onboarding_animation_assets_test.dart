import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:luqma_app/core/constants/app_assets.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/storage/preferences_storage_service.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:luqma_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guards the per-slide onboarding illustrations that replaced the "لقمة"
/// wordmark.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<OnboardingCubit> createCubit() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return OnboardingCubit(
      preferencesStorageService: PreferencesStorageService(prefs),
    );
  }

  Widget createWidgetUnderTest(OnboardingCubit cubit) {
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: BlocProvider<OnboardingCubit>.value(
        value: cubit,
        child: const OnboardingPage(),
      ),
    );
  }

  test('each slide maps to its own cropped illustration asset', () {
    expect(AppAssets.onboardingAnimations, hasLength(3));
    // Slide 1 intentionally keeps the approved burger illustration.
    expect(
      AppAssets.onboardingAnimations[0],
      'assets/animations/onboarding/luqma_onboarding_1.json',
    );
    expect(
      AppAssets.onboardingAnimations[1],
      'assets/animations/onboarding/luqma_onboarding_2.json',
    );
    expect(
      AppAssets.onboardingAnimations[2],
      'assets/animations/onboarding/luqma_onboarding_3.json',
    );
  });

  test('onboarding position keyframes do not collapse to zero-length web paths',
      () async {
    for (final asset in AppAssets.onboardingAnimations) {
      final composition = jsonDecode(await rootBundle.loadString(asset))
          as Map<String, dynamic>;
      final layers = composition['layers'] as List<dynamic>;
      for (final layerValue in layers) {
        final layer = layerValue as Map<String, dynamic>;
        final transform = layer['ks'] as Map<String, dynamic>?;
        final position = transform?['p'] as Map<String, dynamic>?;
        if (position?['a'] != 1 || position?['k'] is! List<dynamic>) {
          continue;
        }

        final keyframes = position!['k'] as List<dynamic>;
        for (var index = 0; index + 1 < keyframes.length; index++) {
          final start = (keyframes[index] as Map<String, dynamic>)['s'];
          final end = (keyframes[index + 1] as Map<String, dynamic>)['s'];
          if (start is! List<dynamic> || end is! List<dynamic>) continue;
          if (start.length < 2 || end.length < 2) continue;

          final startX = (start[0] as num).toDouble();
          final startY = (start[1] as num).toDouble();
          final endX = (end[0] as num).toDouble();
          final endY = (end[1] as num).toDouble();
          final changed = startX != endX || startY != endY;
          if (!changed) continue;

          expect(
            <double>[_asWebFloat(startX), _asWebFloat(startY)],
            isNot(<double>[_asWebFloat(endX), _asWebFloat(endY)]),
            reason:
                '$asset layer ${layer['nm']} frame ${keyframes[index]} → ${keyframes[index + 1]} collapses to a zero-length path on Web',
          );
        }
      }
    }
  });

  testWidgets('onboarding renders an illustration container per slide',
      (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);

    final cubit = await createCubit();
    await tester.pumpWidget(createWidgetUnderTest(cubit));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('onboarding_lottie_animation_0')),
      findsOneWidget,
    );
    // Reveal the second slide and confirm its own illustration container.
    await tester.tap(find.byKey(const Key('onboarding_next_button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('onboarding_lottie_animation_1')),
      findsOneWidget,
    );

    await cubit.close();
  });
}

double _asWebFloat(double value) {
  final bytes = ByteData(4)..setFloat32(0, value);
  return bytes.getFloat32(0);
}
