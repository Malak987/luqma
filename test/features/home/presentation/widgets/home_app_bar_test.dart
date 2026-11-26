import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
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
    ThemeData? theme,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
        body: HomeAppBar(
          userName: userName,
          deliveryAddress: deliveryAddress,
          favoritesCount: favoritesCount,
          hasUnreadNotifications: hasUnread,
          onFavoritesPressed: onFavorites,
          onNotificationsPressed: onNotifications,
          onAddressPressed: onAddress,
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('shows the shared wordmark, greeting and address row',
      (tester) async {
    await pumpHeader(tester, deliveryAddress: 'Minya, El Minya');

    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('Hello, Malak'), findsOneWidget);
    expect(find.text('Minya, El Minya'), findsOneWidget);
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
  });

  testWidgets('localizes the header copy in Arabic RTL', (tester) async {
    await pumpHeader(
      tester,
      locale: const Locale('ar'),
      deliveryAddress: 'المنيا، شارع الجمهورية',
    );

    expect(find.text('مرحباً، Malak'), findsOneWidget);
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
    });
  }

  testWidgets('stacks the greeting under the logo on a narrow screen',
      (tester) async {
    await pumpHeader(tester, size: const Size(320, 640));

    final logoBottom = tester.getRect(find.byType(AppLogo)).bottom;
    final greetingTop = tester.getRect(find.byKey(const Key('home_greeting'))).top;
    expect(greetingTop, greaterThanOrEqualTo(logoBottom));
  });

  testWidgets('keeps the greeting beside the logo on a wide screen',
      (tester) async {
    await pumpHeader(tester, size: const Size(430, 900));

    final logoCenter = tester.getCenter(find.byType(AppLogo)).dy;
    final greetingCenter =
        tester.getCenter(find.byKey(const Key('home_greeting'))).dy;
    expect((logoCenter - greetingCenter).abs(), lessThan(24));
  });

  testWidgets('sizes the wordmark compactly instead of the login hero size',
      (tester) async {
    await pumpHeader(tester);
    final logo = tester.getRect(find.byType(AppLogo));
    expect(logo.height, lessThanOrEqualTo(40));
  });
}
