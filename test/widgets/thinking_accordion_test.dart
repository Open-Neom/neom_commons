import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:neom_commons/ui/widgets/thinking/thinking_accordion.dart';

void main() {
  group('ThinkingAccordion Widget Tests', () {
    testWidgets('ThinkingAccordion renders placeholder message when active and empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ThinkingAccordion(
              thinkingText: '',
              isActive: true,
            ),
          ),
        ),
      );

      // Verify header mounts and default active title displays
      expect(find.text('Procesando razonamiento agéntico...'), findsOneWidget);
      
      // It is already expanded by default since isActive = true
      expect(find.text('Analizando lógica interna...'), findsOneWidget);

      // Tap header to collapse and verify it is hidden
      await tester.tap(find.text('Procesando razonamiento agéntico...'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Analizando lógica interna...'), findsNothing);
    });


    testWidgets('ThinkingAccordion displays actual thinking text and toggles collapse', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ThinkingAccordion(
              thinkingText: 'Paso 1: SQLite FTS5\nPaso 2: WAL habilitado.',
              isActive: false,
              title: 'Mis Lógicas',
            ),
          ),
        ),
      );

      // Verify custom title renders
      expect(find.text('Mis Lógicas'), findsOneWidget);

      // Accordion is closed by default since isActive is false
      expect(find.text('Paso 1: SQLite FTS5\nPaso 2: WAL habilitado.'), findsNothing);

      // Tap to expand
      await tester.tap(find.text('Mis Lógicas'));
      await tester.pump(const Duration(milliseconds: 350));

      // Verify thinking text is now visible
      expect(find.text('Paso 1: SQLite FTS5\nPaso 2: WAL habilitado.'), findsOneWidget);

      // Tap to collapse again
      await tester.tap(find.text('Mis Lógicas'));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Paso 1: SQLite FTS5\nPaso 2: WAL habilitado.'), findsNothing);
    });

  });
}
