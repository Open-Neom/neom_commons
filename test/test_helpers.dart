/// Test helpers and utilities for neom_modules testing
///
/// Provides common mocks, wrappers, and benchmark utilities
// ignore_for_file: avoid_print

library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps a widget with MaterialApp for testing
Widget wrapWithMaterialApp(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? ThemeData.dark(),
    home: Scaffold(body: child),
    debugShowCheckedModeBanner: false,
  );
}

/// Wraps a widget with minimal scaffold
Widget wrapWithScaffold(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

/// Benchmark helper class for measuring widget performance
class WidgetBenchmark {
  final String name;
  final Stopwatch _stopwatch = Stopwatch();
  final List<Duration> _measurements = [];

  WidgetBenchmark(this.name);

  void start() {
    _stopwatch.reset();
    _stopwatch.start();
  }

  void stop() {
    _stopwatch.stop();
    _measurements.add(_stopwatch.elapsed);
  }

  Duration get averageTime {
    if (_measurements.isEmpty) return Duration.zero;
    final total = _measurements.fold<int>(
      0, (sum, d) => sum + d.inMicroseconds,
    );
    return Duration(microseconds: total ~/ _measurements.length);
  }

  Duration get minTime {
    if (_measurements.isEmpty) return Duration.zero;
    return _measurements.reduce((a, b) => a < b ? a : b);
  }

  Duration get maxTime {
    if (_measurements.isEmpty) return Duration.zero;
    return _measurements.reduce((a, b) => a > b ? a : b);
  }

  int get iterations => _measurements.length;

  void printResults() {
    print('═══════════════════════════════════════════');
    print('Benchmark: $name');
    print('───────────────────────────────────────────');
    print('Iterations: $iterations');
    print('Average: ${averageTime.inMicroseconds}μs');
    print('Min: ${minTime.inMicroseconds}μs');
    print('Max: ${maxTime.inMicroseconds}μs');
    print('═══════════════════════════════════════════');
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'iterations': iterations,
    'averageMicroseconds': averageTime.inMicroseconds,
    'minMicroseconds': minTime.inMicroseconds,
    'maxMicroseconds': maxTime.inMicroseconds,
  };
}

/// Runs a benchmark test multiple times
Future<WidgetBenchmark> runWidgetBenchmark({
  required String name,
  required WidgetTester tester,
  required Widget Function() buildWidget,
  int iterations = 100,
  bool warmup = true,
}) async {
  final benchmark = WidgetBenchmark(name);

  // Warmup run
  if (warmup) {
    await tester.pumpWidget(wrapWithMaterialApp(buildWidget()));
    await tester.pumpAndSettle();
  }

  for (int i = 0; i < iterations; i++) {
    benchmark.start();
    await tester.pumpWidget(wrapWithMaterialApp(buildWidget()));
    await tester.pump();
    benchmark.stop();
  }

  return benchmark;
}

/// Animation benchmark helper
Future<WidgetBenchmark> runAnimationBenchmark({
  required String name,
  required WidgetTester tester,
  required Widget Function() buildWidget,
  required Future<void> Function(WidgetTester) triggerAnimation,
  int iterations = 50,
}) async {
  final benchmark = WidgetBenchmark(name);

  for (int i = 0; i < iterations; i++) {
    await tester.pumpWidget(wrapWithMaterialApp(buildWidget()));
    await tester.pumpAndSettle();

    benchmark.start();
    await triggerAnimation(tester);
    await tester.pumpAndSettle();
    benchmark.stop();
  }

  return benchmark;
}

/// Memory usage tracker (simplified)
class MemoryTracker {
  int _initialObjects = 0;

  void markStart() {
    // In real implementation, would use dart:developer
    _initialObjects = 0;
  }

  int get objectsCreated => 0; // Placeholder
}

/// Test data generators
class TestDataGenerator {
  static List<String> generateStrings(int count, {String prefix = 'item'}) {
    return List.generate(count, (i) => '$prefix$i');
  }

  static List<int> generateInts(int count, {int start = 0}) {
    return List.generate(count, (i) => start + i);
  }

  static List<Map<String, dynamic>> generateMaps(int count) {
    return List.generate(count, (i) => {
      'id': 'id_$i',
      'name': 'Name $i',
      'value': i * 10,
      'active': i % 2 == 0,
    });
  }
}

/// Assertion helpers
extension WidgetTesterExtensions on WidgetTester {
  /// Finds widget and verifies it's visible
  Future<void> expectVisible(Finder finder) async {
    expect(finder, findsOneWidget);
    final element = finder.evaluate().first;
    expect(element.mounted, isTrue);
  }

  /// Taps and waits for animations
  Future<void> tapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }

  /// Long press and waits for animations
  Future<void> longPressAndSettle(Finder finder) async {
    await longPress(finder);
    await pumpAndSettle();
  }

  /// Drags and waits for animations
  Future<void> dragAndSettle(Finder finder, Offset offset) async {
    await drag(finder, offset);
    await pumpAndSettle();
  }
}

/// Color helpers for testing
extension ColorMatcher on Color {
  bool isClose(Color other, {int tolerance = 5}) {
    return (red - other.red).abs() <= tolerance &&
           (green - other.green).abs() <= tolerance &&
           (blue - other.blue).abs() <= tolerance &&
           (alpha - other.alpha).abs() <= tolerance;
  }
}

/// Find widgets by key prefix
Finder findByKeyPrefix(String prefix) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    if (key is ValueKey<String>) {
      return key.value.startsWith(prefix);
    }
    return false;
  });
}
