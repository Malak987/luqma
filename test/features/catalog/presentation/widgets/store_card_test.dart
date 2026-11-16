import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/localization/app_localizations.dart';
import 'package:luqma_app/core/theme/app_colors.dart';
import 'package:luqma_app/core/theme/app_theme.dart';
import 'package:luqma_app/features/catalog/domain/entities/store.dart';
import 'package:luqma_app/features/catalog/domain/entities/store_cuisine.dart';
import 'package:luqma_app/features/catalog/presentation/widgets/store_card.dart';

void main() {
  const completeStore = Store(
    id: '00000000-0000-4000-8000-000000000010',
    nameAr: 'مطعم النيل',
    nameEn: 'Nile Kitchen',
    mainCategoryId: '00000000-0000-4000-8000-000000000011',
    isActive: true,
    isOpenNow: true,
    iconUrl: 'https://example.test/nile.png',
    address: 'Sohag, El Gomhoria Street',
    mainCategoryNameAr: 'مطاعم',
    mainCategoryNameEn: 'Restaurants',
    descriptionAr: 'وصف عربي حقيقي للمطعم يوضح الأطباق والخدمة.',
    descriptionEn: 'A real API description of the restaurant and its food.',
    cuisines: <StoreCuisine>[
      StoreCuisine(nameAr: 'مصري', nameEn: 'Egyptian'),
      StoreCuisine(nameAr: 'مشويات', nameEn: 'Grills'),
    ],
    averageRating: 4.5,
    ratingsCount: 18,
    distanceKm: 2.5,
    deliveryTimeMinutes: 35,
    deliveryFee: 20,
    priceLevel: r'$$',
    latitude: 26.56,
    longitude: 31.69,
  );

  Future<void> pumpCard(
    WidgetTester tester,
    Store store, {
    Locale locale = const Locale('en'),
    ThemeData? theme,
    Future<bool> Function(Uri uri)? locationLauncher,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  width: 340,
                  child: StoreCard(
                    store: store,
                    onTap: () {},
                    locationLauncher:
                        locationLauncher ?? ((Uri _) async => true),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders every valid Store API card value in English',
      (tester) async {
    await pumpCard(tester, completeStore);

    expect(find.text('Nile Kitchen'), findsOneWidget);
    expect(find.text('Restaurants'), findsOneWidget);
    expect(find.text('Egyptian • Grills'), findsOneWidget);
    expect(find.text('Open now'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('(18 reviews)'), findsOneWidget);
    expect(find.text('2.5 km'), findsOneWidget);
    expect(find.text('35 min'), findsOneWidget);
    expect(find.text('20 EGP'), findsOneWidget);
    expect(find.text(r'$$'), findsOneWidget);
    expect(find.text(completeStore.descriptionEn!), findsOneWidget);
    expect(find.byKey(const Key('store_location_action')), findsOneWidget);
    expect(find.byKey(const Key('store_discount_badge')), findsNothing);
  });

  testWidgets(
      'uses Arabic API content, RTL direction, and semantic dark colors',
      (tester) async {
    await pumpCard(
      tester,
      completeStore,
      locale: const Locale('ar'),
      theme: AppTheme.dark,
    );

    expect(find.text('مطعم النيل'), findsOneWidget);
    expect(find.text('مطاعم'), findsOneWidget);
    expect(find.text('مصري • مشويات'), findsOneWidget);
    expect(find.text('مفتوح الآن'), findsOneWidget);
    expect(find.text('وصف عربي حقيقي للمطعم يوضح الأطباق والخدمة.'),
        findsOneWidget);
    expect(Directionality.of(tester.element(find.byType(StoreCard))),
        TextDirection.rtl);
    final material = tester.widget<Material>(find
        .descendant(
          of: find.byType(StoreCard),
          matching: find.byType(Material),
        )
        .first);
    final colors = Theme.of(tester.element(find.byType(StoreCard)))
        .extension<AppSemanticColors>()!;
    expect(material.color, colors.surface);
  });

  testWidgets('uses the server status for a visually distinct closed badge',
      (tester) async {
    const closedStore = Store(
      id: '00000000-0000-4000-8000-000000000016',
      nameAr: 'مطعم مغلق',
      nameEn: 'Closed restaurant',
      mainCategoryId: '00000000-0000-4000-8000-000000000017',
      isActive: true,
      isOpenNow: false,
    );
    await pumpCard(tester, closedStore);

    expect(find.text('Closed now'), findsOneWidget);
    expect(find.byType(ColorFiltered), findsOneWidget);
  });

  testWidgets('omits absent, zero-review, invalid, and unavailable fields',
      (tester) async {
    const partialStore = Store(
      id: '00000000-0000-4000-8000-000000000012',
      nameAr: 'بدون تفاصيل',
      nameEn: 'No details',
      mainCategoryId: '00000000-0000-4000-8000-000000000013',
      isActive: true,
      averageRating: 4.9,
      ratingsCount: 0,
      distanceKm: -1,
      deliveryTimeMinutes: 0,
      deliveryFee: -1,
      priceLevel: '   ',
      latitude: 0,
      longitude: 0,
      address: ' ',
    );
    await pumpCard(tester, partialStore);

    expect(find.text('No details'), findsOneWidget);
    expect(find.byKey(const Key('store_description')), findsNothing);
    expect(find.byKey(const Key('store_location_action')), findsNothing);
    expect(find.text('Open now'), findsNothing);
    expect(find.text('Closed now'), findsNothing);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.byIcon(Icons.near_me_outlined), findsNothing);
    expect(find.byIcon(Icons.timer_outlined), findsNothing);
    expect(find.byIcon(Icons.delivery_dining_outlined), findsNothing);
  });

  testWidgets('bounds long descriptions and remains safe at large text scale',
      (tester) async {
    final longDescription = List<String>.filled(80, 'description').join(' ');
    final store = Store(
      id: '00000000-0000-4000-8000-000000000014',
      nameAr: 'وصف طويل',
      nameEn: 'Long description',
      mainCategoryId: '00000000-0000-4000-8000-000000000015',
      isActive: true,
      descriptionEn: longDescription,
    );
    await pumpCard(tester, store, textScale: 2);

    final description =
        tester.widget<Text>(find.byKey(const Key('store_description')));
    expect(description.maxLines, 2);
    expect(description.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'opens coordinates first and reports a launcher failure gracefully',
      (tester) async {
    Uri? launched;
    await pumpCard(
      tester,
      completeStore,
      locationLauncher: (uri) async {
        launched = uri;
        return true;
      },
    );
    await tester.tap(find.byKey(const Key('store_location_action')));
    await tester.pump();
    expect(launched?.queryParameters['query'], '26.56,31.69');

    await pumpCard(tester, completeStore, locationLauncher: (_) async => false);
    await tester.tap(find.byKey(const Key('store_location_action')));
    await tester.pump();
    expect(find.text('We could not open this restaurant location.'),
        findsOneWidget);
  });
}
