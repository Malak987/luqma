import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_colors.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/core/widgets/app_logo.dart';
import 'package:luqma_app/features/home/presentation/widgets/home_app_bar.dart';

void main() {
  Future<void> pumpHeader(
    WidgetTester tester, {
    String? userName = 'Malak',
    String? deliveryAddress,
    int favoritesCount = 0,
    bool hasUnread = false,
    VoidCallback? onFavorites,
    VoidCallback? onNotifications,
    VoidCallback? onAddress,
    Size size = const Size(390, 844),
    Locale locale = const Locale('en'),
    double textScale = 1,
    double statusBarHeight = 0,
    ThemeData? theme,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      theme: theme ?? AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      // The MediaQuery sits inside the route so the status-bar padding reaches
      // SafeArea deterministically, exactly as it does on a device.
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: EdgeInsets.only(top: statusBarHeight),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Material(
          child: HomeAppBar(
            userName: userName,
            deliveryAddress: deliveryAddress,
            favoritesCount: favoritesCount,
            hasUnreadNotifications: hasUnread,
            onFavoritesPressed: onFavorites,
            onNotificationsPressed: onNotifications,
            onAddressPressed: onAddress,
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  /// Top-level assertions for the "full-width band" contract.
  void expectFullWidthFromTopEdge(WidgetTester tester, Size size) {
    final rect = tester.getRect(find.byKey(const Key('home_header')));
    expect(rect.top, 0, reason: 'the header must start at the absolute top edge');
    expect(rect.left, 0, reason: 'no outer margin on the leading edge');
    expect(rect.right, size.width, reason: 'no outer margin on the trailing edge');
  }

  testWidgets('is a full-width band that starts at the very top edge',
      (tester) async {
    const size = Size(390, 844);
    await pumpHeader(tester, size: size);

    expectFullWidthFromTopEdge(tester, size);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rounds the bottom corners only and paints the theme surface',
      (tester) async {
    await pumpHeader(tester);

    final box = tester.widget<DecoratedBox>(
      find.byKey(const Key('home_header')),
    );
    final decoration = box.decoration as BoxDecoration;
    final radius = decoration.borderRadius! as BorderRadius;

    expect(decoration.color, AppSemanticColors.light.surface);
    expect(radius.topLeft, Radius.zero);
    expect(radius.topRight, Radius.zero);
    expect(radius.bottomLeft, const Radius.circular(28));
    expect(radius.bottomRight, const Radius.circular(28));
    // A flat band, not a floating card.
    expect(decoration.boxShadow, isNull);
    expect(decoration.border, isNull);
  });

  testWidgets('draws behind the status bar and keeps content below it',
      (tester) async {
    const statusBar = 24.0;
    await pumpHeader(tester, statusBarHeight: statusBar);

    final header = tester.getRect(find.byKey(const Key('home_header')));
    expect(header.top, 0);
    // The background reaches the top edge, so the band is taller than its
    // content by exactly the status-bar inset.
    expect(header.height, greaterThan(statusBar));

    final logo = tester.getRect(find.byType(AppLogo));
    expect(logo.top, greaterThanOrEqualTo(statusBar));
    expect(find.text('Hello, Malak'), findsOneWidget);
  });

  testWidgets('uses the dark surface in dark mode', (tester) async {
    await pumpHeader(tester, theme: AppTheme.dark);

    final box = tester.widget<DecoratedBox>(
      find.byKey(const Key('home_header')),
    );
    expect((box.decoration as BoxDecoration).color,
        AppSemanticColors.dark.surface);
  });

  testWidgets('stacks logo row, greeting, headline, address and search',
      (tester) async {
    await pumpHeader(tester, deliveryAddress: 'Minya, El Minya');

    final logoBottom = tester.getRect(find.byType(AppLogo)).bottom;
    final greeting = tester.getRect(find.byKey(const Key('home_greeting')));
    final headline = tester.getRect(find.byKey(const Key('home_headline')));
    final address = tester.getRect(find.byKey(const Key('home_app_bar_address')));
    final search = tester.getRect(find.byKey(const Key('home_search_bar')));

    expect(greeting.top, greaterThanOrEqualTo(logoBottom));
    expect(headline.top, greaterThanOrEqualTo(greeting.bottom));
    expect(address.top, greaterThanOrEqualTo(headline.bottom));
    expect(search.top, greaterThanOrEqualTo(address.bottom));
    expect(search.bottom, lessThanOrEqualTo(tester.getRect(
      find.byKey(const Key('home_header')),
    ).bottom));
  });

  testWidgets('shows the wordmark, greeting, headline, address and search',
      (tester) async {
    await pumpHeader(tester, deliveryAddress: 'Minya, El Minya');

    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('Hello, Malak'), findsOneWidget);
    expect(find.text('What are you craving today?'), findsOneWidget);
    expect(find.text('Minya, El Minya'), findsOneWidget);
    expect(
      find.text('Search for your favorite dish or restaurant...'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('home_app_bar_favorites')), findsOneWidget);
    expect(find.byKey(const Key('home_app_bar_notifications')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back to a name-less greeting', (tester) async {
    await pumpHeader(tester, userName: null);
    expect(find.text('Welcome'), findsOneWidget);
  });

  testWidgets('prompts for an address when none is stored', (tester) async {
    await pumpHeader(tester);
    expect(find.text('Select delivery address'), findsOneWidget);
    expect(find.byIcon(Icons.add_location_alt_outlined), findsOneWidget);
    // The change indicator is always visible.
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
  });

  testWidgets('localizes the header copy in Arabic RTL', (tester) async {
    await pumpHeader(
      tester,
      locale: const Locale('ar'),
      deliveryAddress: 'المنيا، شارع الجمهورية',
    );

    expect(find.text('مرحباً، Malak'), findsOneWidget);
    expect(find.text('ماذا تشتهي اليوم؟'), findsOneWidget);
    expect(find.text('المنيا، شارع الجمهورية'), findsOneWidget);
    expect(find.text('اختر عنوان التوصيل'), findsNothing);
    expect(
      Directionality.of(tester.element(find.byType(HomeAppBar))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the favourites badge only above zero and the unread dot',
      (tester) async {
    await pumpHeader(tester, favoritesCount: 4, hasUnread: true);

    expect(find.byKey(const Key('home_favorites_badge')), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(
      find.byKey(const Key('home_notifications_unread_dot')),
      findsOneWidget,
    );
  });

  testWidgets('hides the badge and the dot when there is nothing to show',
      (tester) async {
    await pumpHeader(tester);

    expect(find.byKey(const Key('home_favorites_badge')), findsNothing);
    expect(
      find.byKey(const Key('home_notifications_unread_dot')),
      findsNothing,
    );
  });

  testWidgets('forwards taps to the provided callbacks', (tester) async {
    var favorites = 0;
    var notifications = 0;
    var address = 0;
    await pumpHeader(
      tester,
      onFavorites: () => favorites++,
      onNotifications: () => notifications++,
      onAddress: () => address++,
    );

    await tester.tap(find.byKey(const Key('home_app_bar_favorites')));
    await tester.tap(find.byKey(const Key('home_app_bar_notifications')));
    await tester.tap(find.byKey(const Key('home_app_bar_address')));
    await tester.pump();

    expect(favorites, 1);
    expect(notifications, 1);
    expect(address, 1);
  });

  testWidgets('leaves the address row inert without a callback',
      (tester) async {
    await pumpHeader(tester);
    await tester.tap(find.byKey(const Key('home_app_bar_address')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reveals the clear action only after typing', (tester) async {
    await pumpHeader(tester);

    expect(find.byKey(const Key('home_search_clear')), findsNothing);

    await tester.enterText(find.byType(TextField), 'pizza');
    await tester.pump();

    expect(find.byKey(const Key('home_search_clear')), findsOneWidget);

    await tester.tap(find.byKey(const Key('home_search_clear')));
    await tester.pump();

    expect(find.text('pizza'), findsNothing);
    expect(find.byKey(const Key('home_search_clear')), findsNothing);
  });

  for (final size in <Size>[
    const Size(320, 640),
    const Size(390, 844),
  ]) {
    testWidgets('does not overflow at ${size.width}px with 2x text',
        (tester) async {
      await pumpHeader(
        tester,
        size: size,
        textScale: 2,
        userName: 'Abdulrahman Mohamed El-Sayed',
        deliveryAddress: 'El Minya, Gomhoria Street, Building 12, Floor 3',
        favoritesCount: 12,
        hasUnread: true,
      );

      expect(tester.takeException(), isNull);
      expectFullWidthFromTopEdge(tester, size);
      // The greeting never sits beside the logo, so a long name cannot squeeze
      // the actions out of the row.
      expect(
        tester.getRect(find.byKey(const Key('home_greeting'))).top,
        greaterThanOrEqualTo(tester.getRect(find.byType(AppLogo)).bottom),
      );
    });
  }

  testWidgets('keeps the greeting below the logo row at every width',
      (tester) async {
    for (final width in <double>[320, 390, 430, 800]) {
      await pumpHeader(tester, size: Size(width, 900));

      expect(
        tester.getRect(find.byKey(const Key('home_greeting'))).top,
        greaterThanOrEqualTo(tester.getRect(find.byType(AppLogo)).bottom),
        reason: 'greeting row must stay under the logo row at ${width}px',
      );
    }
  });

  testWidgets('sizes the wordmark compactly instead of the login hero size',
      (tester) async {
    await pumpHeader(tester);
    final logo = tester.getRect(find.byType(AppLogo));
    expect(logo.height, lessThanOrEqualTo(40));
  });
}
