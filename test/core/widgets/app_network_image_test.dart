import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/core/widgets/app_network_image.dart';

void main() {
  Future<void> pumpImage(WidgetTester tester, String? url) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox.square(
      dimension: 100,
      child: AppNetworkImage(
          url: url,
          placeholder:
              const ColoredBox(key: Key('image_fallback'), color: Colors.grey)),
    ))));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'missing, invalid and non-HTTP artwork stays bounded with fallback',
      (tester) async {
    for (final url in <String?>[
      null,
      '',
      '  ',
      '/relative.png',
      'ftp://example.test/a.png',
      'https:///missing.png',
      'https://example.test/bad image.png',
      'https://[bad'
    ]) {
      await pumpImage(tester, url);
      expect(find.byKey(const Key('image_fallback')), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
      'network artwork uses Flutter cache and handles test HTTP failure',
      (tester) async {
    // TestWidgetsFlutterBinding rejects network images locally; no external IO.
    await pumpImage(tester, '  https://example.test/store.png  ');
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<NetworkImage>());
    expect((image.image as NetworkImage).url, 'https://example.test/store.png');
    expect(image.fit, BoxFit.cover);
    expect(image.excludeFromSemantics, isTrue);
    expect(find.byKey(const Key('image_fallback')), findsOneWidget);
    expect(find.byKey(const Key('app_network_image_error')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
