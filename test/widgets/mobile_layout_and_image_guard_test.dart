import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/data/translations/core/core_de_translations.dart';
import 'package:neom_commons/data/translations/core/core_en_translations.dart';
import 'package:neom_commons/data/translations/core/core_es_translations.dart';
import 'package:neom_commons/data/translations/core/core_fr_translations.dart';
import 'package:neom_commons/ui/widgets/custom_image.dart';
import 'package:neom_commons/ui/widgets/neom_bottom_app_bar.dart';
import 'package:neom_commons/ui/widgets/neom_bottom_app_bar_item.dart';
import 'package:neom_commons/utils/constants/translations/app_translation_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';

void main() {
  group('NeomBottomAppBar narrow-screen overflow guard', () {
    testWidgets('5 tabs with long labels do not overflow at 320px width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.2),
            ),
            child: Scaffold(
              body: const SizedBox.shrink(),
              bottomNavigationBar: NeomBottomAppBar(
                color: Colors.white70,
                selectedColor: Colors.white,
                notchedShape: const CircularNotchedRectangle(),
                onTabSelected: (_) {},
                currentIndex: 0,
                items: [
                  NeomBottomAppBarItem(
                    iconData: Icons.book,
                    text: 'Más Escuchado',
                  ),
                  NeomBottomAppBarItem(
                    iconData: Icons.analytics,
                    text: 'Informes',
                  ),
                  NeomBottomAppBarItem(
                    iconData: Icons.show_chart,
                    text: 'Tus temas',
                  ),
                  NeomBottomAppBarItem(
                    iconData: Icons.payments,
                    text: 'Regalías',
                  ),
                  NeomBottomAppBarItem(
                    iconData: Icons.pie_chart,
                    text: 'Resumen',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Más Escuchado'), findsOneWidget);
    });
  });

  group('Network image URL validation & headers', () {
    test('rejects empty, null, relative, and unavailable EMXI legacy URLs', () {
      AppConfig.instance.appInUse = AppInUse.e;
      expect(isValidNetworkImageUrl(''), isFalse);
      expect(isValidNetworkImageUrl('   '), isFalse);
      expect(isValidNetworkImageUrl('null'), isFalse);
      expect(
        isValidNetworkImageUrl('/wp-content/uploads/2025/02/PORTADA.jpg'),
        isFalse,
      );
      expect(
        isValidNetworkImageUrl(
          'https://www.escritoresmxi.org/wp-content/uploads/2025/02/cover.png',
        ),
        isFalse,
      );

      expect(
        isValidNetworkImageUrl(
          'https://firebasestorage.googleapis.com/v0/b/emxi-9c5b5.appspot.com/o/cover.jpg',
        ),
        isTrue,
      );
      expect(
        isValidNetworkImageUrl(
          'https://images.metmuseum.org/CRDImages/ep/original/DP-14286-001.jpg',
        ),
        isTrue,
      );
      expect(
        isValidNetworkImageUrl('https://archive.org/services/img/quijote'),
        isTrue,
      );
    });

    test('platformImageProvider never throws on empty or hostless URI', () {
      expect(platformImageProvider(''), isA<MemoryImage>());
      expect(
        platformImageProvider('/wp-content/uploads/2025/02/PORTADA.jpg'),
        isA<MemoryImage>(),
      );
      expect(neomImageHttpHeaders['User-Agent'], contains('Mozilla/5.0'));
    });
  });

  group('Dashboard translation capitalization', () {
    test('all 4 core translation tables capitalize Dashboard', () {
      expect(
        CoreEsTranslations.values[AppTranslationConstants.dashboard],
        'Dashboard',
      );
      expect(
        CoreEnTranslations.values[AppTranslationConstants.dashboard],
        'Dashboard',
      );
      expect(
        CoreFrTranslations.values[AppTranslationConstants.dashboard],
        'Dashboard',
      );
      expect(
        CoreDeTranslations.values[AppTranslationConstants.dashboard],
        'Dashboard',
      );
    });
  });
}
