import 'package:flutter_test/flutter_test.dart';
import 'package:neom_commons/ui/widgets/thinking/thinking_parser.dart';

void main() {
  group('ThinkingParser Streaming Tests', () {
    test('Standard completed think block', () {
      const text = '<think>Analizando dependencias\nSQLite WAL optimizado\n</think>La base de datos está lista.';
      final result = ThinkingParser.parse(text);

      expect(result.thinkingContent, 'Analizando dependencias\nSQLite WAL optimizado');
      expect(result.finalContent, 'La base de datos está lista.');
      expect(result.isThinkingActive, false);
    });

    test('Active/streaming unclosed think block', () {
      const text = '<think>Cargando índices vectoriales...';
      final result = ThinkingParser.parse(text);

      expect(result.thinkingContent, 'Cargando índices vectoriales...');
      expect(result.finalContent, '');
      expect(result.isThinkingActive, true);
    });

    test('Text without any think tags', () {
      const text = 'Hola, soy Itzli. ¿En qué te puedo ayudar hoy?';
      final result = ThinkingParser.parse(text);

      expect(result.thinkingContent, '');
      expect(result.finalContent, text);
      expect(result.isThinkingActive, false);
    });

    test('Empty text parse safely', () {
      final result = ThinkingParser.parse('');

      expect(result.thinkingContent, '');
      expect(result.finalContent, '');
      expect(result.isThinkingActive, false);
    });

    test('Thinking active state conjoined with final response stream starts', () {
      const text = '<think>Decidiendo canal</think>Hola';
      final result = ThinkingParser.parse(text);

      expect(result.thinkingContent, 'Decidiendo canal');
      expect(result.finalContent, 'Hola');
      expect(result.isThinkingActive, false);
    });
  });
}
