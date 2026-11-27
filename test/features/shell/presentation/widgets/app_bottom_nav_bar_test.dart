import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_colors.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/shell/presentation/cubit/main_shell_state.dart';
import 'package:luqma_app/features/shell/presentation/widgets/app_bottom_nav_bar.dart';

void main() {
  for (final locale in [const Locale('ar'), const Locale('en')]) {
    for (final dark in [false, true]) {
      for (final tab in MainShellTab.values) {
        testWidgets('responsive pill navigation $locale dark=$dark tab=$tab',
            (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 600));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          MainShellTab? tapped;
          final copy = AppLocalizations(locale).navigation;
          final items = [
            AppNavItem(
                tab: MainShellTab.home,
                icon: Icons.home_rounded,
                label: copy.home),
            AppNavItem(
                tab: MainShellTab.restaurants,
                icon: Icons.storefront_rounded,
                label: copy.restaurants),
            AppNavItem(
                tab: MainShellTab.cart,
                icon: Icons.shopping_cart_outlined,
                label: copy.cart,
                badgeCount: 7),
            AppNavItem(
                tab: MainShellTab.favorites,
                icon: Icons.favorite_border_rounded,
                label: copy.favorites,
                badgeCount: 123),
            AppNavItem(
                tab: MainShellTab.account,
                icon: Icons.person_outline_rounded,
                label: copy.account),
          ];
          await tester.pumpWidget(MaterialApp(
            locale: locale,
            theme: dark ? AppTheme.dark : AppTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(2),
                    disableAnimations: true),
                child: child!),
            home: Scaffold(
                bottomNavigationBar: AppBottomNavBar(
                    items: items,
                    currentTab: tab,
                    onSelected: (value) => tapped = value)),
          ));
          await tester.pump();
          expect(
              find.byKey(const Key('bottom_navigation_pill')), findsOneWidget);
          for (final item in items) {
            final button = find.byKey(Key('nav_${item.tab.name}'));
            expect(button, findsOneWidget);
            expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
            final semantics = tester.widget<Semantics>(find
                .descendant(of: button, matching: find.byType(Semantics))
                .first);
            expect(semantics.properties.selected, item.tab == tab);
          }
          expect(find.text('99+'), findsOneWidget);
          expect(find.text(items.firstWhere((item) => item.tab == tab).label),
              findsOneWidget);
          final active = find.descendant(
              of: find.byKey(Key('nav_${tab.name}')),
              matching: find.byType(AnimatedContainer));
          final container = tester.widget<AnimatedContainer>(active);
          expect(container.duration, Duration.zero);
          expect(
              (container.decoration! as BoxDecoration).color,
              (dark ? AppSemanticColors.dark : AppSemanticColors.light)
                  .primary);
          await tester.tap(find.byKey(const Key('nav_cart')));
          expect(tapped, MainShellTab.cart);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
