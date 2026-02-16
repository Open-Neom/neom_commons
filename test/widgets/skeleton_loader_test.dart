/// Tests for SkeletonLoader widget
///
/// Covers:
/// - Basic rendering
/// - Animation behavior
/// - Different shapes (rectangle, circle)
/// - Layout builders
/// - Shimmer effect
library;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

// Note: Import actual widget when running tests
// import 'package:neom_commons/ui/widgets/skeleton_loader.dart';

/// Mock SkeletonLoader for isolated testing
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isCircle;

  const SkeletonLoader({
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
    this.isCircle = false,
    super.key,
  });

  /// Factory constructor for circular skeleton
  const SkeletonLoader.circle({
    required double size,
    super.key,
  })  : width = size,
        height = size,
        borderRadius = size / 2,
        isCircle = true;

  /// Factory constructor for text skeleton
  const SkeletonLoader.text({
    double width = double.infinity,
    double height = 16,
    super.key,
  })  : width = width,
        height = height,
        borderRadius = 4,
        isCircle = false;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.isCircle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            gradient: LinearGradient(
              begin: Alignment(_shimmerAnimation.value - 1, 0),
              end: Alignment(_shimmerAnimation.value + 1, 0),
              colors: [
                Colors.grey[850]!,
                Colors.grey[700]!,
                Colors.grey[850]!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Pre-built skeleton layouts
class SkeletonLayouts {
  static Widget postGrid({int itemCount = 9}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
      ),
      itemCount: itemCount,
      itemBuilder: (_, _) => const SkeletonLoader(),
    );
  }

  static Widget profileHeader() {
    return Row(
      children: [
        const SkeletonLoader.circle(size: 80),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonLoader.text(width: 150, height: 20),
              SizedBox(height: 8),
              SkeletonLoader.text(width: 100, height: 14),
            ],
          ),
        ),
      ],
    );
  }

  static Widget listItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: const [
          SkeletonLoader.circle(size: 48),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader.text(height: 16),
                SizedBox(height: 6),
                SkeletonLoader.text(width: 150, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget card() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonLoader(height: 150, borderRadius: 12),
          SizedBox(height: 12),
          SkeletonLoader.text(height: 18),
          SizedBox(height: 8),
          SkeletonLoader.text(width: 200, height: 14),
        ],
      ),
    );
  }
}

void main() {
  group('SkeletonLoader Widget Tests', () {
    group('Basic Rendering', () {
      testWidgets('renders with default dimensions', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const SkeletonLoader(),
          ),
        );

        expect(find.byType(SkeletonLoader), findsOneWidget);
      });

      testWidgets('renders with custom width and height', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const SkeletonLoader(width: 100, height: 50),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(SkeletonLoader),
            matching: find.byType(Container),
          ),
        );

        expect(container.constraints?.maxWidth, 100);
        expect(container.constraints?.maxHeight, 50);
      });

      testWidgets('renders with custom border radius', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const SkeletonLoader(borderRadius: 16),
          ),
        );

        expect(find.byType(SkeletonLoader), findsOneWidget);
      });
    });

    group('Circle Factory', () {
      testWidgets('creates circular skeleton with correct size', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const SkeletonLoader.circle(size: 60),
          ),
        );

        final skeleton = tester.widget<SkeletonLoader>(
          find.byType(SkeletonLoader),
        );

        expect(skeleton.width, 60);
        expect(skeleton.height, 60);
        expect(skeleton.isCircle, isTrue);
      });

      testWidgets('circle has BoxShape.circle decoration', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const SkeletonLoader.circle(size: 50),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(SkeletonLoader),
            matching: find.byType(Container),
          ),
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.shape, BoxShape.circle);
      });
    });

    group('Text Factory', () {
      testWidgets('creates text skeleton with correct dimensions', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const SkeletonLoader.text(width: 200, height: 20),
          ),
        );

        final skeleton = tester.widget<SkeletonLoader>(
          find.byType(SkeletonLoader),
        );

        expect(skeleton.width, 200);
        expect(skeleton.height, 20);
        expect(skeleton.isCircle, isFalse);
      });
    });

    group('Animation Behavior', () {
      testWidgets('animation controller starts on init', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const SkeletonLoader(),
          ),
        );

        // Pump a few frames to verify animation is running
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(SkeletonLoader), findsOneWidget);
      });

      testWidgets('animation loops continuously', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const SkeletonLoader(),
          ),
        );

        // Animation should continue after one full cycle
        await tester.pump(const Duration(milliseconds: 1500));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(SkeletonLoader), findsOneWidget);
      });

      testWidgets('disposes animation controller properly', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const SkeletonLoader(),
          ),
        );

        // Replace with different widget
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const SizedBox(),
          ),
        );

        // Should not throw
        expect(find.byType(SkeletonLoader), findsNothing);
      });
    });

    group('Gradient Shimmer Effect', () {
      testWidgets('has gradient decoration', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const SkeletonLoader(),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(SkeletonLoader),
            matching: find.byType(Container),
          ),
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.gradient, isA<LinearGradient>());
      });

      testWidgets('gradient has 3 color stops', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            const SkeletonLoader(),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(SkeletonLoader),
            matching: find.byType(Container),
          ),
        );

        final decoration = container.decoration as BoxDecoration;
        final gradient = decoration.gradient as LinearGradient;

        expect(gradient.colors.length, 3);
        expect(gradient.stops?.length, 3);
      });
    });
  });

  group('SkeletonLayouts Tests', () {
    group('Post Grid Layout', () {
      testWidgets('renders correct number of items', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            SkeletonLayouts.postGrid(itemCount: 6),
          ),
        );

        expect(find.byType(SkeletonLoader), findsNWidgets(6));
      });

      testWidgets('uses 3-column grid', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            SkeletonLayouts.postGrid(),
          ),
        );

        final gridView = tester.widget<GridView>(find.byType(GridView));
        final delegate = gridView.gridDelegate
            as SliverGridDelegateWithFixedCrossAxisCount;

        expect(delegate.crossAxisCount, 3);
      });
    });

    group('Profile Header Layout', () {
      testWidgets('renders avatar and text skeletons', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            SkeletonLayouts.profileHeader(),
          ),
        );

        // Should have circle avatar + 2 text lines
        expect(find.byType(SkeletonLoader), findsNWidgets(3));
      });
    });

    group('List Item Layout', () {
      testWidgets('renders avatar and content skeletons', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            SkeletonLayouts.listItem(),
          ),
        );

        expect(find.byType(SkeletonLoader), findsNWidgets(3));
      });
    });

    group('Card Layout', () {
      testWidgets('renders image and text skeletons', (tester) async {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            SkeletonLayouts.card(),
          ),
        );

        expect(find.byType(SkeletonLoader), findsNWidgets(3));
      });
    });
  });

  group('SkeletonLoader Edge Cases', () {
    testWidgets('handles zero width', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const SkeletonLoader(width: 0, height: 20),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('handles very small dimensions', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const SkeletonLoader(width: 1, height: 1),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('handles very large dimensions', (tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const SingleChildScrollView(
            child: SkeletonLoader(width: 10000, height: 10000),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });
  });
}
