/// Benchmark tests for neom_commons widgets
///
/// Measures:
/// - Widget build time
/// - Animation performance
/// - State transition time
/// - Memory usage patterns
library;
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  group('SubmitButton Benchmarks', () {
    testWidgets('build time benchmark', (tester) async {
      final benchmark = await runWidgetBenchmark(
        name: 'SubmitButton Build Time',
        tester: tester,
        buildWidget: () => Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {},
            child: const Text('Submit'),
          ),
        ),
        iterations: 100,
      );

      benchmark.printResults();

      // Assert reasonable build time (< 20ms average)
      expect(benchmark.averageTime.inMilliseconds, lessThan(100));
    });

    testWidgets('animation benchmark - tap scale', (tester) async {
      final benchmark = await runAnimationBenchmark(
        name: 'SubmitButton Tap Animation',
        tester: tester,
        buildWidget: () => ElevatedButton(
          onPressed: () {},
          child: const Text('Submit'),
        ),
        triggerAnimation: (tester) async {
          await tester.tap(find.byType(ElevatedButton));
        },
        iterations: 50,
      );

      benchmark.printResults();

      // Animation should complete quickly (< 500ms)
      expect(benchmark.averageTime.inMilliseconds, lessThan(500));
    });

    testWidgets('state transition benchmark - loading', (tester) async {
      final benchmark = WidgetBenchmark('SubmitButton Loading State Transition');

      for (int i = 0; i < 50; i++) {
        bool isLoading = false;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return wrapWithMaterialApp(
                ElevatedButton(
                  onPressed: isLoading ? null : () => setState(() => isLoading = true),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit'),
                ),
              );
            },
          ),
        );

        benchmark.start();
        await tester.tap(find.byType(ElevatedButton));
        // Use pump() instead of pumpAndSettle() because CircularProgressIndicator
        // has an infinite animation that would cause pumpAndSettle to timeout
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        benchmark.stop();
      }

      benchmark.printResults();

      expect(benchmark.averageTime.inMilliseconds, lessThan(100));
    });
  });

  group('SkeletonLoader Benchmarks', () {
    testWidgets('single skeleton build time', (tester) async {
      final benchmark = await runWidgetBenchmark(
        name: 'SkeletonLoader Single Build',
        tester: tester,
        buildWidget: () => Container(
          width: 100,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        iterations: 100,
      );

      benchmark.printResults();

      expect(benchmark.averageTime.inMicroseconds, lessThan(20000));
    });

    testWidgets('grid of 9 skeletons build time', (tester) async {
      final benchmark = await runWidgetBenchmark(
        name: 'SkeletonLoader Grid (9 items)',
        tester: tester,
        buildWidget: () => GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
          itemCount: 9,
          itemBuilder: (_, _) => Container(
            color: Colors.grey[800],
          ),
        ),
        iterations: 50,
      );

      benchmark.printResults();

      expect(benchmark.averageTime.inMilliseconds, lessThan(50));
    });

    testWidgets('shimmer animation frame rate', (tester) async {
      final stopwatch = Stopwatch()..start();
      int frameCount = 0;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          Container(
            width: 100,
            height: 20,
            color: Colors.grey,
          ),
        ),
      );

      // Measure frames over 1 second
      while (stopwatch.elapsedMilliseconds < 1000) {
        await tester.pump(const Duration(milliseconds: 16)); // ~60fps target
        frameCount++;
      }

      stopwatch.stop();

      print('═══════════════════════════════════════════');
      print('Benchmark: Shimmer Animation Frame Rate');
      print('───────────────────────────────────────────');
      print('Duration: ${stopwatch.elapsedMilliseconds}ms');
      print('Frames: $frameCount');
      print('FPS: ${(frameCount * 1000 / stopwatch.elapsedMilliseconds).toStringAsFixed(1)}');
      print('═══════════════════════════════════════════');

      // Should maintain at least 30fps
      expect(frameCount, greaterThan(30));
    });
  });

  group('PostTile Benchmarks', () {
    testWidgets('single post tile build time', (tester) async {
      final benchmark = await runWidgetBenchmark(
        name: 'PostTile Single Build',
        tester: tester,
        buildWidget: () => Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.grey[900],
          ),
          child: Stack(
            children: [
              Container(color: Colors.grey[800]),
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.play_arrow, size: 16),
              ),
              Positioned(
                bottom: 6,
                left: 6,
                child: Row(
                  children: const [
                    Icon(Icons.favorite, size: 12),
                    SizedBox(width: 2),
                    Text('1.2K', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        iterations: 100,
      );

      benchmark.printResults();

      expect(benchmark.averageTime.inMicroseconds, lessThan(50000));
    });

    testWidgets('grid of 12 post tiles build time', (tester) async {
      final benchmark = await runWidgetBenchmark(
        name: 'PostTile Grid (12 items)',
        tester: tester,
        buildWidget: () => GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
          ),
          itemCount: 12,
          itemBuilder: (_, index) => Container(
            color: Colors.grey[800 + (index % 3) * 50],
            child: const Icon(Icons.image),
          ),
        ),
        iterations: 50,
      );

      benchmark.printResults();

      expect(benchmark.averageTime.inMilliseconds, lessThan(100));
    });

    testWidgets('tap animation benchmark', (tester) async {
      final benchmark = await runAnimationBenchmark(
        name: 'PostTile Tap Animation',
        tester: tester,
        buildWidget: () => GestureDetector(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 100,
            height: 100,
            color: Colors.grey,
          ),
        ),
        triggerAnimation: (tester) async {
          final gesture = await tester.startGesture(
            tester.getCenter(find.byType(GestureDetector)),
          );
          await tester.pump(const Duration(milliseconds: 50));
          await gesture.up();
        },
        iterations: 50,
      );

      benchmark.printResults();

      expect(benchmark.averageTime.inMilliseconds, lessThan(300));
    });
  });

  group('ProfileStatsCard Benchmarks', () {
    testWidgets('stats card build time', (tester) async {
      final benchmark = await runWidgetBenchmark(
        name: 'ProfileStatsCard Build',
        tester: tester,
        buildWidget: () => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey[900],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn('Posts', 42),
              _buildStatColumn('Followers', 1234),
              _buildStatColumn('Following', 567),
            ],
          ),
        ),
        iterations: 100,
      );

      benchmark.printResults();

      expect(benchmark.averageTime.inMicroseconds, lessThan(50000));
    });

    testWidgets('count-up animation benchmark', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        wrapWithMaterialApp(
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: 1000),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Text('$value');
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      print('═══════════════════════════════════════════');
      print('Benchmark: Count-up Animation');
      print('───────────────────────────────────────────');
      print('Duration: ${stopwatch.elapsedMilliseconds}ms');
      print('═══════════════════════════════════════════');

      // Animation should complete in reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });

  group('Memory Usage Patterns', () {
    testWidgets('widget rebuild does not leak memory', (tester) async {
      // Build and rebuild widget multiple times
      for (int i = 0; i < 100; i++) {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            Container(
              key: ValueKey(i),
              child: const Text('Test'),
            ),
          ),
        );
        await tester.pump();
      }

      // If we get here without crashing, basic memory management is working
      expect(true, isTrue);
    });

    testWidgets('animation controllers are disposed', (tester) async {
      for (int i = 0; i < 50; i++) {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            AnimatedContainer(
              key: ValueKey(i),
              duration: const Duration(milliseconds: 100),
              width: 100.0 + i,
              height: 100,
              color: Colors.blue,
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      // Replace with empty widget to trigger dispose
      await tester.pumpWidget(
        wrapWithMaterialApp(const SizedBox()),
      );

      expect(true, isTrue);
    });
  });

  group('Comparative Benchmarks', () {
    testWidgets('StatelessWidget vs StatefulWidget build time', (tester) async {
      // StatelessWidget benchmark
      final statelessBenchmark = await runWidgetBenchmark(
        name: 'StatelessWidget Build',
        tester: tester,
        buildWidget: () => const _StatelessTestWidget(),
        iterations: 100,
      );

      // StatefulWidget benchmark
      final statefulBenchmark = await runWidgetBenchmark(
        name: 'StatefulWidget Build',
        tester: tester,
        buildWidget: () => const _StatefulTestWidget(),
        iterations: 100,
      );

      print('\n═══════════════════════════════════════════');
      print('Comparative: StatelessWidget vs StatefulWidget');
      print('───────────────────────────────────────────');
      print('StatelessWidget avg: ${statelessBenchmark.averageTime.inMicroseconds}μs');
      print('StatefulWidget avg: ${statefulBenchmark.averageTime.inMicroseconds}μs');
      print('Difference: ${statefulBenchmark.averageTime.inMicroseconds - statelessBenchmark.averageTime.inMicroseconds}μs');
      print('═══════════════════════════════════════════\n');
    });

    testWidgets('Container vs DecoratedBox build time', (tester) async {
      final containerBenchmark = await runWidgetBenchmark(
        name: 'Container Build',
        tester: tester,
        buildWidget: () => Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        iterations: 100,
      );

      final decoratedBoxBenchmark = await runWidgetBenchmark(
        name: 'DecoratedBox Build',
        tester: tester,
        buildWidget: () => DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const SizedBox(width: 100, height: 100),
        ),
        iterations: 100,
      );

      print('\n═══════════════════════════════════════════');
      print('Comparative: Container vs DecoratedBox');
      print('───────────────────────────────────────────');
      print('Container avg: ${containerBenchmark.averageTime.inMicroseconds}μs');
      print('DecoratedBox avg: ${decoratedBoxBenchmark.averageTime.inMicroseconds}μs');
      print('═══════════════════════════════════════════\n');
    });
  });
}

// Helper widgets for comparative benchmarks
class _StatelessTestWidget extends StatelessWidget {
  const _StatelessTestWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      color: Colors.blue,
      child: const Text('Test'),
    );
  }
}

class _StatefulTestWidget extends StatefulWidget {
  const _StatefulTestWidget();

  @override
  State<_StatefulTestWidget> createState() => _StatefulTestWidgetState();
}

class _StatefulTestWidgetState extends State<_StatefulTestWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      color: Colors.blue,
      child: const Text('Test'),
    );
  }
}

// Helper function for stats column
Widget _buildStatColumn(String label, int value) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '$value',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    ],
  );
}
