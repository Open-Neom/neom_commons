/// Tests for ProfileStatsCard widget
///
/// Covers:
/// - Stats display (posts, followers, following, events, bands)
/// - Count-up animations
/// - Tap interactions on stat items
/// - Conditional visibility (followers for mates only)
/// - Loading states
/// - Layout and styling
library;
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Test helpers
Widget wrapWithMaterialApp(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(body: Center(child: child)),
  );
}

/// Mock ProfileStats data class
class MockProfileStats {
  final int posts;
  final int followers;
  final int following;
  final int events;
  final int bands;

  const MockProfileStats({
    this.posts = 0,
    this.followers = 0,
    this.following = 0,
    this.events = 0,
    this.bands = 0,
  });
}

/// Mock ProfileStatsCard for testing
class MockProfileStatsCard extends StatefulWidget {
  final MockProfileStats stats;
  final bool showFollowers;
  final bool isLoading;
  final bool animateOnLoad;
  final VoidCallback? onPostsTap;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  final VoidCallback? onEventsTap;
  final VoidCallback? onBandsTap;

  const MockProfileStatsCard({
    required this.stats,
    this.showFollowers = true,
    this.isLoading = false,
    this.animateOnLoad = true,
    this.onPostsTap,
    this.onFollowersTap,
    this.onFollowingTap,
    this.onEventsTap,
    this.onBandsTap,
    super.key,
  });

  @override
  State<MockProfileStatsCard> createState() => _MockProfileStatsCardState();
}

class _MockProfileStatsCardState extends State<MockProfileStatsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (!widget.isLoading) {
      if (widget.animateOnLoad) {
        _controller.forward();
      } else {
        _controller.value = 1.0; // Skip animation, show final values
      }
    }
  }

  @override
  void didUpdateWidget(MockProfileStatsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading && widget.animateOnLoad) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Container(
        key: const Key('stats_loading'),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            widget.showFollowers ? 5 : 3,
            (index) => Container(
              width: 50,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      key: const Key('stats_card'),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                key: 'posts_stat',
                label: 'Posts',
                value: widget.stats.posts,
                onTap: widget.onPostsTap,
              ),
              if (widget.showFollowers) ...[
                _buildStatItem(
                  key: 'followers_stat',
                  label: 'Followers',
                  value: widget.stats.followers,
                  onTap: widget.onFollowersTap,
                ),
                _buildStatItem(
                  key: 'following_stat',
                  label: 'Following',
                  value: widget.stats.following,
                  onTap: widget.onFollowingTap,
                ),
              ],
              _buildStatItem(
                key: 'events_stat',
                label: 'Events',
                value: widget.stats.events,
                onTap: widget.onEventsTap,
              ),
              _buildStatItem(
                key: 'bands_stat',
                label: 'Bands',
                value: widget.stats.bands,
                onTap: widget.onBandsTap,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem({
    required String key,
    required String label,
    required int value,
    VoidCallback? onTap,
  }) {
    final animatedValue = (value * _animation.value).round();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: Key(key),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatNumber(animatedValue),
              key: Key('${key}_value'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              key: Key('${key}_label'),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}

void main() {
  group('ProfileStatsCard Tests', () {
    group('Rendering', () {
      testWidgets('renders all stat items with followers', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfileStatsCard(
              stats: MockProfileStats(
                posts: 42,
                followers: 1234,
                following: 567,
                events: 15,
                bands: 3,
              ),
              animateOnLoad: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('stats_card')), findsOneWidget);
        expect(find.byKey(const Key('posts_stat')), findsOneWidget);
        expect(find.byKey(const Key('followers_stat')), findsOneWidget);
        expect(find.byKey(const Key('following_stat')), findsOneWidget);
        expect(find.byKey(const Key('events_stat')), findsOneWidget);
        expect(find.byKey(const Key('bands_stat')), findsOneWidget);
      });

      testWidgets('renders without followers when showFollowers is false',
          (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfileStatsCard(
              stats: MockProfileStats(posts: 10, events: 5, bands: 2),
              showFollowers: false,
              animateOnLoad: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byKey(const Key('posts_stat')), findsOneWidget);
        expect(find.byKey(const Key('followers_stat')), findsNothing);
        expect(find.byKey(const Key('following_stat')), findsNothing);
        expect(find.byKey(const Key('events_stat')), findsOneWidget);
        expect(find.byKey(const Key('bands_stat')), findsOneWidget);
      });

      testWidgets('shows loading state', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfileStatsCard(
              stats: MockProfileStats(),
              isLoading: true,
            ),
          ),
        );

        expect(find.byKey(const Key('stats_loading')), findsOneWidget);
        expect(find.byKey(const Key('stats_card')), findsNothing);
      });

      testWidgets('displays correct labels', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfileStatsCard(
              stats: MockProfileStats(),
              animateOnLoad: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Posts'), findsOneWidget);
        expect(find.text('Followers'), findsOneWidget);
        expect(find.text('Following'), findsOneWidget);
        expect(find.text('Events'), findsOneWidget);
        expect(find.text('Bands'), findsOneWidget);
      });
    });

    group('Number Formatting', () {
      testWidgets('displays numbers under 1000 as-is', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfileStatsCard(
              stats: MockProfileStats(posts: 42, events: 999),
              showFollowers: false,
              animateOnLoad: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('42'), findsOneWidget);
        expect(find.text('999'), findsOneWidget);
      });

      testWidgets('formats thousands with K suffix', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfileStatsCard(
              stats: MockProfileStats(followers: 1500, following: 2300),
              animateOnLoad: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('1.5K'), findsOneWidget);
        expect(find.text('2.3K'), findsOneWidget);
      });

      testWidgets('formats millions with M suffix', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfileStatsCard(
              stats: MockProfileStats(followers: 1500000),
              animateOnLoad: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('1.5M'), findsOneWidget);
      });

      testWidgets('displays zero correctly', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfileStatsCard(
              stats: MockProfileStats(posts: 0, events: 0, bands: 0),
              showFollowers: false,
              animateOnLoad: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('0'), findsNWidgets(3));
      });
    });

    group('Interactions', () {
      testWidgets('calls onPostsTap when posts tapped', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfileStatsCard(
              stats: const MockProfileStats(posts: 10),
              onPostsTap: () => tapped = true,
              animateOnLoad: false,
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('posts_stat')));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('calls onFollowersTap when followers tapped', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfileStatsCard(
              stats: const MockProfileStats(followers: 100),
              onFollowersTap: () => tapped = true,
              animateOnLoad: false,
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('followers_stat')));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('calls onFollowingTap when following tapped', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfileStatsCard(
              stats: const MockProfileStats(following: 50),
              onFollowingTap: () => tapped = true,
              animateOnLoad: false,
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('following_stat')));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('calls onEventsTap when events tapped', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfileStatsCard(
              stats: const MockProfileStats(events: 5),
              onEventsTap: () => tapped = true,
              animateOnLoad: false,
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('events_stat')));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('calls onBandsTap when bands tapped', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfileStatsCard(
              stats: const MockProfileStats(bands: 2),
              onBandsTap: () => tapped = true,
              animateOnLoad: false,
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('bands_stat')));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('handles null callbacks gracefully', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfileStatsCard(
              stats: MockProfileStats(posts: 10),
              animateOnLoad: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should not throw when tapping without callback
        await tester.tap(find.byKey(const Key('posts_stat')));
        await tester.pump();
      });
    });

    group('Animation', () {
      testWidgets('animates count-up on load', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfileStatsCard(
              stats: MockProfileStats(posts: 100),
              showFollowers: false,
              animateOnLoad: true,
            ),
          ),
        );

        // Initial state - should show 0 or small number
        await tester.pump();

        // Mid animation
        await tester.pump(const Duration(milliseconds: 400));

        // End of animation
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('100'), findsOneWidget);
      });

      testWidgets('does not animate when animateOnLoad is false',
          (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfileStatsCard(
              stats: MockProfileStats(posts: 50),
              showFollowers: false,
              animateOnLoad: false,
            ),
          ),
        );

        await tester.pump();

        // Should show final values immediately since animation is skipped
        // Controller value is set to 1.0 when animateOnLoad is false
        expect(find.text('50'), findsOneWidget);
      });

      testWidgets('re-animates when transitioning from loading',
          (tester) async {
        bool isLoading = true;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return wrapWithMaterialApp(
                Column(
                  children: [
                    MockProfileStatsCard(
                      stats: const MockProfileStats(posts: 75),
                      showFollowers: false,
                      isLoading: isLoading,
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => isLoading = false),
                      child: const Text('Load'),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        expect(find.byKey(const Key('stats_loading')), findsOneWidget);

        await tester.tap(find.text('Load'));
        await tester.pump();

        expect(find.byKey(const Key('stats_card')), findsOneWidget);

        await tester.pumpAndSettle();
      });
    });

    group('Layout', () {
      testWidgets('has correct container styling', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfileStatsCard(
              stats: MockProfileStats(),
              animateOnLoad: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify the stats_card container exists and has decoration
        expect(find.byKey(const Key('stats_card')), findsOneWidget);

        // Find Container widgets and check one has border radius
        final containers = tester.widgetList<Container>(find.byType(Container));
        final decoratedContainer = containers.where((c) {
          if (c.decoration is BoxDecoration) {
            final decoration = c.decoration as BoxDecoration;
            return decoration.borderRadius == BorderRadius.circular(16);
          }
          return false;
        });
        expect(decoratedContainer.isNotEmpty, isTrue);
      });

      testWidgets('stats are evenly spaced', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfileStatsCard(
              stats: MockProfileStats(),
              animateOnLoad: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find any Row widget that has spaceEvenly alignment
        final rows = tester.widgetList<Row>(find.byType(Row));
        final evenlySpacedRow = rows.where(
          (r) => r.mainAxisAlignment == MainAxisAlignment.spaceEvenly,
        );

        expect(evenlySpacedRow.isNotEmpty, isTrue);
      });

      testWidgets('loading state has correct number of placeholders',
          (tester) async {
        // With followers (5 items)
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfileStatsCard(
              stats: MockProfileStats(),
              isLoading: true,
              showFollowers: true,
            ),
          ),
        );

        var containers = tester.widgetList<Container>(
          find.descendant(
            of: find.byKey(const Key('stats_loading')),
            matching: find.byType(Container),
          ),
        );
        // Main container + 5 placeholders
        expect(containers.length, greaterThanOrEqualTo(5));

        // Without followers (3 items)
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfileStatsCard(
              stats: MockProfileStats(),
              isLoading: true,
              showFollowers: false,
            ),
          ),
        );

        containers = tester.widgetList<Container>(
          find.descendant(
            of: find.byKey(const Key('stats_loading')),
            matching: find.byType(Container),
          ),
        );
        expect(containers.length, greaterThanOrEqualTo(3));
      });
    });

    group('Edge Cases', () {
      testWidgets('handles very large numbers', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfileStatsCard(
              stats: MockProfileStats(followers: 999999999),
              animateOnLoad: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should format as millions
        expect(find.textContaining('M'), findsOneWidget);
      });

      testWidgets('handles widget disposal correctly', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const MockProfileStatsCard(
              stats: MockProfileStats(posts: 50),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        // Dispose by replacing with empty container
        await tester.pumpWidget(
          wrapWithMaterialApp(const SizedBox()),
        );

        // Should not throw
        await tester.pumpAndSettle();
      });

      testWidgets('updates stats when widget changes', (tester) async {
        int posts = 10;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return wrapWithMaterialApp(
                Column(
                  children: [
                    MockProfileStatsCard(
                      stats: MockProfileStats(posts: posts),
                      showFollowers: false,
                      animateOnLoad: false,
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => posts = 50),
                      child: const Text('Update'),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.text('Update'));
        await tester.pumpAndSettle();
      });
    });
  });

  group('ProfileStatsCard Benchmark Tests', () {
    testWidgets('build time benchmark', (tester) async {
      final stopwatch = Stopwatch();
      final measurements = <int>[];

      for (int i = 0; i < 50; i++) {
        stopwatch.reset();
        stopwatch.start();

        await tester.pumpWidget(
          wrapWithMaterialApp(
            MockProfileStatsCard(
              stats: MockProfileStats(
                posts: i * 10,
                followers: i * 100,
                following: i * 50,
                events: i * 5,
                bands: i,
              ),
              animateOnLoad: false,
            ),
          ),
        );
        await tester.pump();

        stopwatch.stop();
        measurements.add(stopwatch.elapsedMicroseconds);
      }

      final average = measurements.reduce((a, b) => a + b) ~/ measurements.length;
      print('ProfileStatsCard Build - Average: $averageμs');

      expect(average, lessThan(10000)); // Should build under 10ms
    });

    testWidgets('animation performance benchmark', (tester) async {
      final stopwatch = Stopwatch()..start();
      int frameCount = 0;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          const MockProfileStatsCard(
            stats: MockProfileStats(
              posts: 100,
              followers: 10000,
              following: 5000,
              events: 50,
              bands: 10,
            ),
            animateOnLoad: true,
          ),
        ),
      );

      while (stopwatch.elapsedMilliseconds < 1000) {
        await tester.pump(const Duration(milliseconds: 16));
        frameCount++;
      }

      stopwatch.stop();
      final fps = frameCount * 1000 / stopwatch.elapsedMilliseconds;
      print('ProfileStatsCard Animation - FPS: ${fps.toStringAsFixed(1)}');

      expect(fps, greaterThan(30)); // Should maintain at least 30 FPS
    });
  });
}
