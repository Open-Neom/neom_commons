@TestOn('browser')
library;

// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/foundation.dart' show debugPrintSynchronously;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/ui/widgets/images/handled_cached_network_image.dart';
import 'package:neom_commons/ui/widgets/images/web_network_image_impl.dart';

// Real browser-decodable images, with no HTTP server or external network.
String imageUrl(String name) =>
    '${Uri.dataFromString('<svg xmlns="http://www.w3.org/2000/svg" width="2" height="2">'
    '<rect width="2" height="2" fill="red"/></svg>', mimeType: 'image/svg+xml', encoding: utf8)}#$name';

void phase(String value) =>
    debugPrintSynchronously('Image retry fixture: $value');

Future<void> waitForBrowserDecode(
  WidgetTester tester,
  html.ImageElement image,
) async {
  await tester.runAsync(() async {
    // Create every wait in the real async zone. A DOM future created during
    // pump/tap can queue its completion in FakeAsync while runAsync waits.
    // Polling also handles an image that finished before this callback starts.
    final elapsed = Stopwatch()..start();
    while (image.complete != true || image.naturalWidth == 0) {
      if (elapsed.elapsed >= const Duration(seconds: 5)) {
        throw TestFailure(
          'Browser image did not decode within 5s '
          '(complete=${image.complete}, naturalWidth=${image.naturalWidth}).',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  });
}

void main() {
  late List<html.ImageElement> probes;
  late int errorsRemaining;

  setUp(() {
    probes = [];
    errorsRemaining = 1;
    debugWebNetworkImageProbeFactory = () {
      final image = html.ImageElement();
      probes.add(image);
      if (errorsRemaining > 0) {
        errorsRemaining--;
        // Model a transient browser error before this valid image's real
        // decode event. A subsequent retry must let the browser load it.
        scheduleMicrotask(() => image.dispatchEvent(html.Event('error')));
      }
      return image;
    };
  });

  tearDown(() {
    debugWebNetworkImageProbeFactory = null;
  });

  for (final ownsTap in [false, true]) {
    testWidgets(
      'Retry reloads the same failed image and recovers with own tap=$ownsTap',
      (tester) async {
        final url = imageUrl('recover-$ownsTap');
        var ownTaps = 0;
        var parentTaps = 0;
        Widget subject() => MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () => parentTaps++,
              child: HandledCachedNetworkImage(
                url,
                height: 200,
                width: 200,
                enableFullScreen: false,
                function: ownsTap ? () => ownTaps++ : null,
                placeholder: const Text('Loading artwork'),
              ),
            ),
          ),
        );

        phase('own tap=$ownsTap: before initial pumpWidget');
        await tester.pumpWidget(subject());
        await tester.pump();
        phase('own tap=$ownsTap: initial failure rendered');
        expect(find.text('Failed to load'), findsOneWidget);
        expect(probes, hasLength(1));

        // Rebuilds and a revisit retain the failed outcome instead of
        // repeatedly requesting a broken image without a user action.
        await tester.pumpWidget(subject());
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(subject());
        await tester.pump();
        expect(probes, hasLength(1));
        expect(find.text('Retry (3)'), findsOneWidget);

        phase('own tap=$ownsTap: before Retry tap');
        await tester.tap(find.text('Retry (3)'));
        await tester.pump();
        phase('own tap=$ownsTap: Retry delivered');
        expect(probes, hasLength(2));
        expect(
          probes.map((image) => image.getAttribute('src')),
          everyElement(url),
        );
        expect(ownTaps, 0);
        expect(parentTaps, 0);

        // The second probe succeeds through the real browser image decoder.
        phase('own tap=$ownsTap: before real-zone decode wait');
        await waitForBrowserDecode(tester, probes.last);
        phase('own tap=$ownsTap: browser decode complete');
        await tester.pump();
        expect(find.text('Failed to load'), findsNothing);
        expect(find.text('Loading artwork'), findsNothing);
        expect(find.byType(HtmlElementView), findsOneWidget);

        await tester.tap(find.byType(HtmlElementView));
        await tester.pump();
        expect(ownTaps, ownsTap ? 1 : 0);
        expect(parentTaps, ownsTap ? 0 : 1);

        // Successful images continue to use the normal outcome cache.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(subject());
        expect(probes, hasLength(2));
        expect(find.byType(HtmlElementView), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        phase('own tap=$ownsTap: completed');
      },
    );
  }

  testWidgets('manual retries are bounded and reset for a different image', (
    tester,
  ) async {
    errorsRemaining = 10;
    Widget subject(String url) => MaterialApp(
      home: Scaffold(
        body: HandledCachedNetworkImage(
          url,
          height: 200,
          width: 200,
          enableFullScreen: false,
          placeholder: const Text('Loading artwork'),
        ),
      ),
    );

    final url = imageUrl('bounded-retries');
    phase('budget: before initial pumpWidget');
    await tester.pumpWidget(subject(url));
    await tester.pump();
    for (var retries = 3; retries > 0; retries--) {
      await tester.tap(find.text('Retry ($retries)'));
      await tester.pump();
      await tester.pump();
    }
    expect(probes, hasLength(4));
    expect(find.text('Failed to load'), findsOneWidget);
    expect(find.textContaining('Retry ('), findsNothing);
    await tester.pump(const Duration(seconds: 30));
    expect(probes, hasLength(4));

    final nextUrl = imageUrl('new-image-new-budget');
    await tester.pumpWidget(subject(nextUrl));
    await tester.pump();
    expect(probes, hasLength(5));
    expect(probes.last.getAttribute('src'), nextUrl);
    expect(find.text('Retry (3)'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    phase('budget: completed');
  });

  testWidgets(
    'late events from a previous image cannot replace a new failure',
    (tester) async {
      errorsRemaining = 2;
      Widget subject(String url) => MaterialApp(
        home: Scaffold(
          body: HandledCachedNetworkImage(
            url,
            height: 200,
            width: 200,
            enableFullScreen: false,
            placeholder: const Text('Loading artwork'),
          ),
        ),
      );

      phase('late events: before initial pumpWidget');
      await tester.pumpWidget(subject(imageUrl('old-event-source')));
      await tester.pump();
      final oldProbe = probes.single;
      final nextUrl = imageUrl('keep-new-failure');
      await tester.pumpWidget(subject(nextUrl));
      await tester.pump();
      expect(probes, hasLength(2));
      expect(find.text('Failed to load'), findsOneWidget);

      oldProbe.dispatchEvent(html.Event('load'));
      await tester.pump();
      expect(find.text('Failed to load'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      phase('late events: completed');
      await tester.pumpWidget(subject(nextUrl));
      expect(probes, hasLength(2));
      expect(find.text('Failed to load'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
