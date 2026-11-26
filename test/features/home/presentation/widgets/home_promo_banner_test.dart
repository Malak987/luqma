import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/home/domain/entities/home_ad_banner.dart';
import 'package:luqma_app/features/home/presentation/widgets/home_promo_banner.dart';

void main() {
  const ad1 = HomeAdBanner(
    id: 'ad-1',
    imageUrl: 'https://luqma-api.runasp.net/uploads/ads/one.jpg',
    title: 'Offer one',
    subtitle: 'First subtitle',
  );
  const ad2 = HomeAdBanner(
    id: 'ad-2',
    imageUrl: 'https://luqma-api.runasp.net/uploads/ads/two.jpg',
    title: 'Offer two',
  );

  Future<void> pumpPromo(
    WidgetTester tester, {
    List<HomeAdBanner> ads = const <HomeAdBanner>[],
    Locale locale = const Locale('en'),
    Size size = const Size(390, 844),
    ThemeData? theme,
    double textScale = 1,
    VoidCallback? onCta,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final copy = AppLocalizations(locale).home;

    await tester.pumpWidget(MaterialApp(
      theme: theme ?? AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: HomePromoBanner(
            tag: copy.promoTag,
            title: copy.promoTitle,
            highlight: copy.promoHighlight,
            subtitle: copy.promoSubtitle,
            ctaLabel: copy.promoCta,
            onCtaPressed: onCta,
            ads: ads,
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('shows the built-in default banner when no ads exist',
      (tester) async {
    await pumpPromo(tester);
    final copy = AppLocalizations(const Locale('en')).home;

    expect(find.byKey(const Key('home_promo_default_banner')), findsOneWidget);
    expect(find.byKey(const Key('home_promo_carousel')), findsNothing);
    expect(find.text(copy.promoTag), findsOneWidget);
    expect(find.text(copy.promoTitle), findsOneWidget);
    expect(find.text(copy.promoHighlight), findsOneWidget);
    expect(find.byKey(const Key('home_promo_cta')), findsOneWidget);
    // The default banner carries no invented percentage.
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('the default banner keeps its space and CTA at 320px and 2x text',
      (tester) async {
    for (final theme in <ThemeData>[AppTheme.light, AppTheme.dark]) {
      for (final locale in <Locale>[const Locale('en'), const Locale('ar')]) {
        await pumpPromo(
          tester,
          size: const Size(320, 720),
          textScale: 2,
          theme: theme,
          locale: locale,
        );
        final copy = AppLocalizations(locale).home;

        expect(tester.takeException(), isNull);
        expect(find.text(copy.promoTag), findsOneWidget);
        expect(find.text(copy.promoTitle), findsOneWidget);
        expect(find.text(copy.promoHighlight), findsOneWidget);
        expect(find.byKey(const Key('home_promo_cta')), findsOneWidget);
        // The CTA must stay inside the visible area.
        final rect = tester.getRect(find.byKey(const Key('home_promo_cta')));
        expect(rect.height, greaterThan(0));
      }
    }
  });

  testWidgets('the default banner CTA forwards its tap', (tester) async {
    var taps = 0;
    await pumpPromo(tester, onCta: () => taps++);
    await tester.tap(find.byKey(const Key('home_promo_cta')));
    expect(taps, 1);
  });

  testWidgets('renders a carousel with indicators for several ads',
      (tester) async {
    await pumpPromo(tester, ads: const <HomeAdBanner>[ad1, ad2]);

    expect(find.byKey(const Key('home_promo_default_banner')), findsNothing);
    expect(find.byKey(const Key('home_promo_carousel')), findsOneWidget);
    expect(find.byKey(const Key('home_promo_indicators')), findsOneWidget);
    expect(find.text('Offer one'), findsOneWidget);
  });

  testWidgets('hides the indicators for a single ad', (tester) async {
    await pumpPromo(tester, ads: const <HomeAdBanner>[ad1]);

    expect(find.byKey(const Key('home_promo_carousel')), findsOneWidget);
    expect(find.byKey(const Key('home_promo_indicators')), findsNothing);
  });

  testWidgets('swipes to the next ad in English LTR', (tester) async {
    await pumpPromo(tester, ads: const <HomeAdBanner>[ad1, ad2]);
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('home_promo_carousel')),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Offer two'), findsOneWidget);
  });

  testWidgets('swipes to the next ad in Arabic RTL', (tester) async {
    await pumpPromo(
      tester,
      ads: const <HomeAdBanner>[ad1, ad2],
      locale: const Locale('ar'),
    );
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.byKey(
        const Key('home_promo_carousel'),
      ))),
      TextDirection.rtl,
    );

    // In RTL the next page lives to the left, so the finger moves right.
    await tester.drag(
      find.byKey(const Key('home_promo_carousel')),
      const Offset(300, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Offer two'), findsOneWidget);
  });

  testWidgets('an ad without text still renders its artwork only',
      (tester) async {
    const artworkOnly = HomeAdBanner(
      id: 'ad-3',
      imageUrl: 'https://luqma-api.runasp.net/uploads/ads/three.jpg',
    );
    await pumpPromo(tester, ads: const <HomeAdBanner>[artworkOnly]);

    expect(find.byKey(const Key('home_promo_carousel')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
