import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

// Mock Firestore Query latency simulator (avg 150ms per network roundtrip)
Future<String?> mockDbLookup(String slug, String type, bool shouldMatch) async {
  await Future.delayed(const Duration(milliseconds: 150));
  if (shouldMatch) {
    return 'matched_$type';
  }
  return null;
}

// 1. Old Sequential Resolution Simulator
Future<String?> resolveSequential(String slug, {required String matchType}) async {
  final collections = ['profile', 'item', 'event', 'collective', 'post'];
  for (final type in collections) {
    final result = await mockDbLookup(slug, type, type == matchType);
    if (result != null) return result;
  }
  return null;
}

// 2. High-Performance Parallel Resolution Simulator
Future<String?> resolveParallel(String slug, {required String matchType}) async {
  final collections = ['profile', 'item', 'event', 'collective', 'post'];
  final futures = collections.map((type) => mockDbLookup(slug, type, type == matchType));
  final results = await Future.wait(futures);
  for (final result in results) {
    if (result != null) return result;
  }
  return null;
}

void main() {
  group('Slug Resolution Performance Benchmark', () {
    test('Parallel vs Sequential resolution latency benchmark', () async {
      print('Starting Slug Resolution Benchmark...');

      // ── Scenario A: Worst Case (No Match / 404) ──
      // Sequential must query all 5 collections sequentially -> 5 * 150ms = 750ms
      // Parallel queries all 5 collections simultaneously -> 1 * 150ms = 150ms
      print('\nScenario A: No Match (Worst Case / 404 Resolution)');
      
      final seqStopwatch = Stopwatch()..start();
      await resolveSequential('non-existent-slug', matchType: '');
      seqStopwatch.stop();
      print('Sequential Resolution Time: ${seqStopwatch.elapsedMilliseconds} ms');

      final parStopwatch = Stopwatch()..start();
      await resolveParallel('non-existent-slug', matchType: '');
      parStopwatch.stop();
      print('Parallel Resolution Time: ${parStopwatch.elapsedMilliseconds} ms');

      expect(parStopwatch.elapsedMilliseconds, lessThan(seqStopwatch.elapsedMilliseconds ~/ 3));
      final speedup = seqStopwatch.elapsedMilliseconds / parStopwatch.elapsedMilliseconds;
      print('Parallel Speedup Factor: ${speedup.toStringAsFixed(2)}x faster!');

      // ── Scenario B: Medium Case (Matches on 4th collection - Collective) ──
      print('\nScenario B: Match on "collective" (4th priority)');
      
      final seqMatchStopwatch = Stopwatch()..start();
      await resolveSequential('daft-punk', matchType: 'collective');
      seqMatchStopwatch.stop();
      print('Sequential Match Time: ${seqMatchStopwatch.elapsedMilliseconds} ms');

      final parMatchStopwatch = Stopwatch()..start();
      await resolveParallel('daft-punk', matchType: 'collective');
      parMatchStopwatch.stop();
      print('Parallel Match Time: ${parMatchStopwatch.elapsedMilliseconds} ms');
      
      expect(parMatchStopwatch.elapsedMilliseconds, lessThan(seqMatchStopwatch.elapsedMilliseconds));
    });
  });
}
