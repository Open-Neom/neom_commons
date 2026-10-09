import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/common_routes.dart';
import 'package:neom_commons/ui/legal_document_data.dart';
import 'package:neom_commons/ui/legal_page.dart';
import 'package:neom_commons/ui/terms_conditions_page.dart';
import 'package:neom_core/app_properties.dart';

const _metadata = {
  'controllerName': 'Marca Legal',
  'privacyEmail': 'contacto@marca.example',
  'updatedAt': '2026-10-04',
  'themeColor': '#123456',
  'privateKey': 'MUST_NOT_APPEAR',
  'reviewNotes': ['NOT_PUBLIC'],
};

class _Bundle extends CachingAssetBundle {
  final Map<String, String> strings;
  final Completer<String>? delayedDocument;
  _Bundle(this.strings, {this.delayedDocument});

  @override
  Future<ByteData> load(String key) async =>
      throw FlutterError('Missing test asset');

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key.endsWith('.md') && delayedDocument != null) {
      return delayedDocument!.future;
    }
    final value = strings[key];
    if (value == null) throw FlutterError('Missing test asset');
    return value;
  }
}

LegalDocumentData _data({
  Map<String, Object>? metadata = _metadata,
  String privacy = 'https://marca.example/politica-de-privacidad/',
  String site = 'https://legacy.example/',
  String appName = '',
}) => LegalDocumentData.fromSources(
  metadataJson: metadata == null ? null : jsonEncode(metadata),
  privacyPolicyUrl: privacy,
  fallbackAppName: appName,
  fallbackContactEmail: 'old@legacy.example',
  fallbackSiteUrl: site,
);

List<TextSpan> _spans(InlineSpan span) => [
  if (span is TextSpan) span,
  if (span is TextSpan)
    for (final child in span.children ?? <InlineSpan>[]) ..._spans(child),
];

void main() {
  tearDown(() => AppProperties.appProperties = {});

  test(
    'metadata supplies legal identity and resolves only public placeholders',
    () {
      final data = _data();
      expect(data.appName, 'Marca Legal');
      expect(data.contactEmail, 'contacto@marca.example');
      expect(data.themeColor, 0xff123456);
      final rendered = data.render(
        '{{APP_NAME}}|{{CONTROLLER_NAME}}|{{CONTACT_EMAIL}}|'
        '{{UPDATED_AT}}|{{SITE_URL}}|{{PRIVACY_URL}}|{{TERMS_URL}}|{{ACCOUNT_DELETION_URL}}',
      );
      expect(
        rendered,
        'Marca Legal|Marca Legal|contacto@marca.example|2026-10-04|'
        'https://marca.example|https://marca.example/politica-de-privacidad/|'
        'https://marca.example/terminos-y-condiciones/|https://marca.example/eliminar-cuenta/',
      );
      expect(rendered, isNot(contains('MUST_NOT_APPEAR')));
      expect(() => data.render('{{PRIVATE_KEY}}'), throwsFormatException);
    },
  );

  test('product brand and legal controller remain distinct', () {
    final metadata = {
      ..._metadata,
      'controllerName': 'Mi Empresa SA',
      'appName': 'Old metadata brand',
    };
    expect(
      _data(
        metadata: metadata,
        appName: 'Mi App',
      ).render('{{APP_NAME}} / {{CONTROLLER_NAME}}'),
      'Mi App / Mi Empresa SA',
    );
    expect(_data(metadata: metadata).appName, 'Old metadata brand');
    expect(_data().appName, 'Marca Legal');
  });

  test('unknown, malformed and nested placeholders fail closed', () {
    final data = _data();
    for (final markdown in [
      '{{foo}}',
      '{{PRIVATE_KEY}}',
      '{{APP_NAME}',
      '{{APP_NAME',
      'APP_NAME}}',
      '{{{APP_NAME}}}',
      '{{APP_{{NAME}}}}',
      '{{}}',
      '{{ APP_NAME }}',
      '{{APP_NAME}} {{CONTACT_EMAIL',
    ]) {
      expect(
        () => data.render(markdown),
        throwsFormatException,
        reason: markdown,
      );
    }
    final nested = _data(
      metadata: {..._metadata, 'controllerName': '{{CONTACT_EMAIL}}'},
    );
    expect(() => nested.render('{{APP_NAME}}'), throwsFormatException);
    expect(
      data.render('{{APP_NAME}} / {{APP_NAME}} / texto sin tokens'),
      'Marca Legal / Marca Legal / texto sin tokens',
    );
  });

  test('legacy legal identity is used only when metadata is absent', () {
    final legacy = _data(metadata: null, privacy: '', appName: 'Legacy name');
    expect(legacy.appName, 'Legacy name');
    expect(legacy.contactEmail, 'old@legacy.example');
    expect(
      legacy.termsUrl.toString(),
      'https://legacy.example/terminos-y-condiciones/',
    );
    expect(legacy.updatedAt, isEmpty);
    expect(legacy.themeColor, 0xff111c41);
    expect(
      () => _data(metadata: {..._metadata, 'privacyEmail': ''}),
      throwsFormatException,
    );
    expect(
      () => _data(metadata: {..._metadata, 'updatedAt': '2026-02-31'}),
      throwsFormatException,
    );
  });

  test('optional theme color uses the web default, invalid colors fail', () {
    final metadata = {..._metadata}..remove('themeColor');
    expect(_data(metadata: metadata).themeColor, 0xff111c41);
    for (final color in ['', '#123', 'red', '#GGGGGG']) {
      expect(
        () => _data(metadata: {..._metadata, 'themeColor': color}),
        throwsFormatException,
        reason: color,
      );
    }
  });

  test('invalid optional canonicals use a separately validated site URL', () {
    for (final url in [
      'http://marca.example/politica-de-privacidad/',
      'https://user:pass@marca.example/politica-de-privacidad/',
      'https://marca.example/politica-de-privacidad/?token=x',
      'https://marca.example/politica-de-privacidad/#x',
      'https://marca.example/other/',
      'https://marca.example:444/politica-de-privacidad/',
    ]) {
      expect(
        _data(privacy: url).origin.toString(),
        'https://legacy.example/',
        reason: url,
      );
      expect(
        () => _data(privacy: url, site: ''),
        throwsFormatException,
        reason: url,
      );
    }
    expect(
      _data(
        privacy: 'https://marca.example/politica-de-privacidad',
      ).origin.toString(),
      'https://marca.example/',
    );
    for (final site in [
      'http://legacy.example/',
      'https://user:pass@legacy.example/',
      'https://legacy.example/?token=x',
      'https://legacy.example/#x',
      'https://legacy.example:444/',
    ]) {
      expect(
        () => _data(privacy: '', site: site),
        throwsFormatException,
        reason: site,
      );
    }
  });

  test('only HTTPS, HTTP, mailto and local anchors are navigable', () {
    for (final url in [
      'https://marca.example/',
      'http://example.org/info',
      'mailto:contacto@marca.example?subject=Eliminar%20cuenta',
      '#derechos',
    ]) {
      expect(legalLinkUri(url), isNotNull, reason: url);
    }
    for (final url in [
      'javascript:alert(1)',
      'data:text/html,test',
      'file:///tmp/private',
      '//other.example',
      '/account/remove',
      'intent://test',
      '#',
      'https://user:pass@example.org',
      'mailto:contacto@marca.example?subject=%0d%0aBcc:x',
    ]) {
      expect(legalLinkUri(url), isNull, reason: url);
    }
    expect(
      legalHeadingAnchor('9. Eliminación y derechos'),
      '9-eliminacion-y-derechos',
    );
  });

  test(
    'informational aliases have no middleware and do not replace account action',
    () {
      final routes = CommonRoutes.routes;
      for (final path in [
        '/terms',
        '/terms/',
        '/terminos-y-condiciones',
        '/terminos-y-condiciones/',
        '/eliminar-cuenta',
        '/eliminar-cuenta/',
      ]) {
        final route = routes.singleWhere((route) => route.name == path);
        expect(route.middlewares, isEmpty, reason: path);
      }
      expect(
        routes.where((route) => route.name == '/account/remove').length,
        1,
      );
    },
  );

  void properties() => AppProperties.appProperties = {
    'appName': 'Marca App',
    'contactEmail': 'old@legacy.example',
    'privacyPolicyUrl': 'https://marca.example/politica-de-privacidad/',
    'siteUrl': 'https://site.example/',
    'landingPageUrl': 'https://legacy.example/',
    'secret': 'MUST_NOT_APPEAR',
  };

  testWidgets('siteUrl has priority over the legacy landingPageUrl', (
    tester,
  ) async {
    properties();
    AppProperties.appProperties['privacyPolicyUrl'] =
        'https://invalid.example/';
    final bundle = _Bundle({
      'assets/privacy_policy.json': jsonEncode(_metadata),
      'assets/legal/terms_conditions.md': '# {{APP_NAME}}\n{{SITE_URL}}',
    });
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultAssetBundle(
          bundle: bundle,
          child: const TermsConditionsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('https://site.example', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text('https://legacy.example', findRichText: true),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy site and identity remain available without metadata', (
    tester,
  ) async {
    properties();
    AppProperties.appProperties.remove('siteUrl');
    AppProperties.appProperties.remove('privacyPolicyUrl');
    final bundle = _Bundle({
      'assets/legal/terms_conditions.md':
          '# {{APP_NAME}}\n{{SITE_URL}}\n{{CONTACT_EMAIL}}',
    });
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultAssetBundle(
          bundle: bundle,
          child: const TermsConditionsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('https://legacy.example', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('old@legacy.example', findRichText: true), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      const Color(0xff111c41),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'terms render metadata branding, all links and bold text without leaking JSON',
    (tester) async {
      properties();
      final bundle = _Bundle({
        'assets/privacy_policy.json': jsonEncode(_metadata),
        'assets/legal/terms_conditions.md':
            '# {{APP_NAME}}\n'
            '**Responsable:** {{CONTROLLER_NAME}}.\n'
            '[Privacidad]({{PRIVACY_URL}}) y [Correo](mailto:{{CONTACT_EMAIL}}?subject=Ayuda)\n'
            '[Ir a derechos](#derechos) y [Bloqueado](javascript:bad)\n'
            '## 1. Derechos\nTexto\n## Derechos\nMás texto\n## Derechos\nFin',
      });
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultAssetBundle(
            bundle: bundle,
            child: const TermsConditionsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final texts = tester.widgetList<RichText>(find.byType(RichText));
      final plain = texts.map((text) => text.text.toPlainText()).join('\n');
      expect(plain, contains('Marca App'));
      expect(plain, contains('Responsable: Marca Legal.'));
      expect(plain, isNot(contains('{{')));
      expect(plain, isNot(contains('MUST_NOT_APPEAR')));
      expect(plain, isNot(contains('NOT_PUBLIC')));
      expect(plain, isNot(contains('old@legacy.example')));
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        const Color(0xff123456),
      );
      final spans = texts.expand((text) => _spans(text.text)).toList();
      expect(
        spans.singleWhere((span) => span.text == 'Privacidad').recognizer,
        isA<TapGestureRecognizer>(),
      );
      expect(
        spans.singleWhere((span) => span.text == 'Correo').recognizer,
        isA<TapGestureRecognizer>(),
      );
      expect(
        spans.singleWhere((span) => span.text == 'Bloqueado').recognizer,
        isNull,
      );
      (spans.singleWhere((span) => span.text == 'Ir a derechos').recognizer
              as TapGestureRecognizer)
          .onTap!();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('deletion page is readable without authentication', (
    tester,
  ) async {
    properties();
    final bundle = _Bundle({
      'assets/privacy_policy.json': jsonEncode(_metadata),
      'assets/legal/account_deletion.md':
          '# Eliminar cuenta\n'
          '[Solicitar](mailto:{{CONTACT_EMAIL}}?subject=Eliminar)\n'
          '[Términos]({{TERMS_URL}})\nÚltima actualización: {{UPDATED_AT}}',
    });
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultAssetBundle(
          bundle: bundle,
          child: const AccountDeletionPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Eliminar cuenta y datos'), findsOneWidget);
    expect(
      find.text('Última actualización: 2026-10-04', findRichText: true),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('async completion after disposal does not update state', (
    tester,
  ) async {
    properties();
    final completer = Completer<String>();
    final bundle = _Bundle({
      'assets/privacy_policy.json': jsonEncode(_metadata),
    }, delayedDocument: completer);
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultAssetBundle(
          bundle: bundle,
          child: const LegalPage(document: LegalDocument.terms),
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    completer.complete('# {{APP_NAME}}');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
