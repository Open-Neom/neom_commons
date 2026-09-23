import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/data/translations/commons/commons_es_translations.dart';
import 'package:neom_commons/ui/previous_version_page.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/utils/constants/core_constants.dart';
import 'package:sint/sint.dart';

class _TestTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'es': CommonsEsTranslations.values,
  };
}

void main() {
  setUp(() {
    Sint.reset();
  });

  tearDown(() {
    Sint.reset();
    AppProperties.appProperties = {};
  });

  testWidgets('PreviousVersionPage renders appName dynamically when set and never hardcoded Cyberneom', (tester) async {
    AppProperties.appProperties = {'appName': 'EMXI'};

    await tester.pumpWidget(
      SintMaterialApp(
        locale: const Locale('es'),
        translations: _TestTranslations(),
        home: const PreviousVersionPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('EMXI'), findsOneWidget);
    expect(find.textContaining('Cyberneom'), findsNothing);
  });

  testWidgets('PreviousVersionPage does not render prevVersion4 when appName is empty', (tester) async {
    AppProperties.appProperties = {'appName': ''};

    await tester.pumpWidget(
      SintMaterialApp(
        locale: const Locale('es'),
        translations: _TestTranslations(),
        home: const PreviousVersionPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Gracias por utilizar'), findsNothing);
    expect(find.textContaining('Cyberneom'), findsNothing);
    // Base message is still present
    expect(find.textContaining(CoreConstants.prevVersion1.tr), findsOneWidget);
  });
}
