import 'package:flutter/material.dart';

/// Shimmer-effect skeleton loader for placeholder content.
///
/// Use this instead of CircularProgressIndicator for better UX
/// during content loading. Supports various shapes and sizes.
///
/// Usage:
/// ```dart
/// // Simple rectangle
/// SkeletonLoader(width: 200, height: 20)
///
/// // Circle (avatar placeholder)
/// SkeletonLoader.circle(radius: 30)
///
/// // Card placeholder
/// SkeletonLoader.card()
///
/// // Post grid placeholder
/// SkeletonLoader.postGrid(itemCount: 9)
/// ```
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isCircle;
  final EdgeInsets? margin;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonLoader({
    this.width,
    this.height,
    this.borderRadius = 4,
    this.isCircle = false,
    this.margin,
    this.baseColor,
    this.highlightColor,
    super.key,
  });

  /// Creates a circular skeleton (for avatars)
  const SkeletonLoader.circle({
    required double radius,
    this.margin,
    this.baseColor,
    this.highlightColor,
    super.key,
  })  : width = radius * 2,
        height = radius * 2,
        borderRadius = radius,
        isCircle = true;

  /// Creates a text line skeleton
  factory SkeletonLoader.text({
    double width = double.infinity,
    double height = 14,
    EdgeInsets? margin,
    Key? key,
  }) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: 4,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 4),
      key: key,
    );
  }

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? Colors.grey[850]!;
    final highlightColor = widget.highlightColor ?? Colors.grey[700]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: widget.isCircle
                ? null
                : BorderRadius.circular(widget.borderRadius),
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Pre-built skeleton layouts for common UI patterns
class SkeletonLayouts {
  SkeletonLayouts._();

  /// Post grid skeleton (Instagram-style)
  static Widget postGrid({int itemCount = 9, int crossAxisCount = 3}) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        childAspectRatio: 1,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const SkeletonLoader(borderRadius: 0);
      },
    );
  }

  /// Profile header skeleton
  static Widget profileHeader() {
    return Column(
      children: [
        // Cover image
        const SkeletonLoader(
          height: 200,
          borderRadius: 0,
        ),
        const SizedBox(height: 16),
        // Avatar
        Transform.translate(
          offset: const Offset(0, -60),
          child: Column(
            children: [
              const SkeletonLoader.circle(radius: 50),
              const SizedBox(height: 12),
              // Name
              const SkeletonLoader(width: 150, height: 20, borderRadius: 8),
              const SizedBox(height: 8),
              // Bio
              SkeletonLoader.text(width: 200),
              SkeletonLoader.text(width: 160),
            ],
          ),
        ),
      ],
    );
  }

  /// Card skeleton
  static Widget card({
    double height = 120,
    bool showImage = true,
    int textLines = 2,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (showImage) ...[
            const SkeletonLoader(
              width: 80,
              height: 80,
              borderRadius: 8,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SkeletonLoader(height: 16, borderRadius: 4),
                const SizedBox(height: 8),
                for (int i = 0; i < textLines; i++) ...[
                  SkeletonLoader(
                    height: 12,
                    width: i == textLines - 1 ? 100 : double.infinity,
                    borderRadius: 4,
                  ),
                  if (i < textLines - 1) const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// List item skeleton
  static Widget listItem({bool showAvatar = true, int textLines = 2}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (showAvatar) ...[
            const SkeletonLoader.circle(radius: 24),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(height: 14, width: 120, borderRadius: 4),
                const SizedBox(height: 6),
                for (int i = 1; i < textLines; i++) ...[
                  SkeletonLoader(
                    height: 12,
                    width: i == textLines - 1 ? 80 : double.infinity,
                    borderRadius: 4,
                  ),
                  if (i < textLines - 1) const SizedBox(height: 4),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Comment skeleton
  static Widget comment() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader.circle(radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(height: 12, width: 80, borderRadius: 4),
                const SizedBox(height: 6),
                SkeletonLoader.text(width: double.infinity),
                SkeletonLoader.text(width: 150),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Stats row skeleton
  static Widget statsRow({int itemCount = 3}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(itemCount, (index) {
        return Column(
          children: const [
            SkeletonLoader(width: 40, height: 20, borderRadius: 4),
            SizedBox(height: 4),
            SkeletonLoader(width: 60, height: 12, borderRadius: 4),
          ],
        );
      }),
    );
  }

  /// Dashboard KPI cards skeleton (2 or 4 columns)
  static Widget dashboardKpis({int count = 4, bool isWide = false}) {
    return GridView.count(
      crossAxisCount: isWide ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: isWide ? 2.2 : 2.4,
      children: List.generate(count, (_) => _kpiCardSkeleton()),
    );
  }

  static Widget _kpiCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            SkeletonLoader(width: 16, height: 16, borderRadius: 4),
            SizedBox(width: 6),
            Expanded(child: SkeletonLoader(height: 10, borderRadius: 4)),
          ]),
          SizedBox(height: 10),
          SkeletonLoader(width: 90, height: 20, borderRadius: 6),
          SizedBox(height: 6),
          SkeletonLoader(width: 60, height: 8, borderRadius: 4),
        ],
      ),
    );
  }

  /// Dashboard full-page skeleton (KPIs + chart + sections)
  static Widget dashboardFull({bool isWide = false}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          const SkeletonLoader(width: 200, height: 20, borderRadius: 6),
          const SizedBox(height: 4),
          const SkeletonLoader(width: 160, height: 10, borderRadius: 4),
          const SizedBox(height: 16),
          // KPI cards
          dashboardKpis(count: 4, isWide: isWide),
          const SizedBox(height: 20),
          // Section header 2
          const SkeletonLoader(width: 180, height: 20, borderRadius: 6),
          const SizedBox(height: 12),
          dashboardKpis(count: 4, isWide: isWide),
          const SizedBox(height: 24),
          // Chart placeholder
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(13),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 140, height: 16, borderRadius: 4),
                Spacer(),
                SkeletonLoader(height: 150, borderRadius: 8),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Two cards side by side
          if (isWide)
            const Row(
              children: [
                Expanded(child: SkeletonLoader(height: 200, borderRadius: 16)),
                SizedBox(width: 16),
                Expanded(child: SkeletonLoader(height: 200, borderRadius: 16)),
              ],
            )
          else ...[
            const SkeletonLoader(height: 200, borderRadius: 16),
            const SizedBox(height: 16),
            const SkeletonLoader(height: 200, borderRadius: 16),
          ],
        ],
      ),
    );
  }
}
