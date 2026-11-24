import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

import '../../../app_flavour.dart';
import '../custom_image.dart' show isValidNetworkImageUrl, neomImageHttpHeaders;
import 'web_network_image_stub.dart'
    if (dart.library.js_interop) 'web_network_image_impl.dart';

/// Enhanced cached network image with skeleton loading, retry mechanism,
/// and better error handling.
///
/// Features:
/// - Skeleton shimmer loading placeholder
/// - Retry button on failure
/// - Progress indicator during download
/// - Full screen view on tap
/// - Smooth fade-in animation
class HandledCachedNetworkImage extends StatefulWidget {
  final String mediaUrl;
  final BoxFit fit;
  final double? height;
  final double? width;
  final bool enableFullScreen;
  final Duration fadeInDuration;
  final Function()? function;
  final BorderRadius? borderRadius;
  final bool showProgress;
  final Widget? placeholder;
  final Color? backgroundColor;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int? maxWidthDiskCache;
  final int? maxHeightDiskCache;
  final bool useFullResolution;

  const HandledCachedNetworkImage(
    this.mediaUrl, {
    this.fit = BoxFit.cover,
    this.height,
    this.width,
    this.enableFullScreen = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.function,
    this.borderRadius,
    this.showProgress = false,
    this.placeholder,
    this.backgroundColor,
    this.memCacheWidth,
    this.memCacheHeight,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
    this.useFullResolution = false,
    super.key,
  });

  @override
  State<HandledCachedNetworkImage> createState() =>
      _HandledCachedNetworkImageState();
}

class _HandledCachedNetworkImageState extends State<HandledCachedNetworkImage> {
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void didUpdateWidget(HandledCachedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaUrl != widget.mediaUrl) _retryCount = 0;
  }

  void _handleTap() {
    if (widget.function != null) {
      widget.function!();
    } else if (widget.enableFullScreen && widget.mediaUrl.isNotEmpty) {
      HapticFeedback.lightImpact();
      Sint.toNamed(AppRouteConstants.imageFullScreen, arguments: [widget.mediaUrl]);
    }
  }

  void _retry() {
    if (_retryCount < _maxRetries) {
      HapticFeedback.lightImpact();
      setState(() {
        _retryCount++;
      });
    }
  }

  String get _effectiveUrl {
    final trimmed = widget.mediaUrl.trim();
    if (isValidNetworkImageUrl(trimmed)) {
      return trimmed;
    }
    final fallback = AppProperties.getAppLogoUrl().trim();
    if (isValidNetworkImageUrl(fallback)) {
      return fallback;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = _effectiveUrl;
    final Widget content;

    if (effectiveUrl.isEmpty) {
      content = _buildErrorWidget();
    } else if (kIsWeb) {
      // On web, use native HTML <img> via HtmlElementView to bypass CanvasKit CORS
      content = buildWebNativeImage(
        imageUrl: effectiveUrl,
        retryToken: _retryCount,
        height: widget.height,
        width: widget.width,
        fit: widget.fit,
        placeholder: _buildPlaceholder(),
        errorWidget: _buildErrorWidget(),
      );
    } else {
      final dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 2.5);
      final targetMemWidth = widget.useFullResolution
          ? null
          : (widget.memCacheWidth ??
              ((widget.width != null &&
                      widget.width!.isFinite &&
                      widget.width! > 0)
                  ? (widget.width! * dpr).round().clamp(32, 2048)
                  : null));
      final targetMemHeight = widget.useFullResolution
          ? null
          : (widget.memCacheHeight ??
              ((targetMemWidth == null &&
                      widget.height != null &&
                      widget.height!.isFinite &&
                      widget.height! > 0)
                  ? (widget.height! * dpr).round().clamp(32, 2048)
                  : null));

      content = CachedNetworkImage(
        key: ValueKey('$effectiveUrl-$_retryCount'),
        imageUrl: effectiveUrl,
        httpHeaders: neomImageHttpHeaders,
        height: widget.height,
        width: widget.width,
        memCacheWidth: targetMemWidth,
        memCacheHeight: targetMemHeight,
        maxWidthDiskCache: widget.maxWidthDiskCache,
        maxHeightDiskCache: widget.maxHeightDiskCache,
        fit: widget.fit,
        fadeInDuration: widget.fadeInDuration,
        placeholder: (context, url) => _buildPlaceholder(),
        progressIndicatorBuilder: widget.showProgress
            ? (context, url, progress) => _buildProgressIndicator(progress)
            : null,
        errorWidget: (context, url, error) => _buildErrorWidget(),
      );
    }

    final wrappedContent = widget.borderRadius != null
        ? ClipRRect(borderRadius: widget.borderRadius!, child: content)
        : content;

    // The native image adds its own platform-view overlay. Keep the tap
    // handler above it in the gesture tree so the error widget's Retry can
    // win the gesture instead of being covered by a second overlay.
    if (kIsWeb) {
      if (widget.function != null || widget.enableFullScreen) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleTap,
          child: wrappedContent,
        );
      }
      return wrappedContent;
    }

    if (widget.function != null || widget.enableFullScreen) {
      return GestureDetector(
        onTap: _handleTap,
        child: wrappedContent,
      );
    }

    return wrappedContent;
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) return widget.placeholder!;

    return _ShimmerPlaceholder(
      height: widget.height,
      width: widget.width,
      borderRadius: widget.borderRadius,
      backgroundColor: widget.backgroundColor,
    );
  }

  Widget _buildProgressIndicator(DownloadProgress progress) {
    return Container(
      height: widget.height,
      width: widget.width,
      color: widget.backgroundColor ?? Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: progress.progress,
                strokeWidth: 3,
                backgroundColor: Colors.grey[800],
                valueColor: const AlwaysStoppedAnimation(Colors.white54),
              ),
            ),
            if (progress.progress != null) ...[
              const SizedBox(height: 8),
              Text(
                '${(progress.progress! * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final canRetry = _retryCount < _maxRetries;

    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey[900],
        borderRadius: widget.borderRadius,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // For small containers, show only icon
          if (constraints.maxHeight < 80) {
            return Center(
              child: GestureDetector(
                onTap: canRetry ? _retry : null,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.grey[600],
                  size: constraints.maxHeight * 0.5,
                ),
              ),
            );
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.broken_image_outlined,
                color: Colors.grey[600],
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to load',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              if (canRetry && constraints.maxHeight >= 120) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _retry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Retry (${_maxRetries - _retryCount})',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ShimmerPlaceholder extends StatefulWidget {
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const _ShimmerPlaceholder({
    this.height,
    this.width,
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

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
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              gradient: LinearGradient(
                begin: Alignment(_shimmerAnimation.value - 1, 0),
                end: Alignment(_shimmerAnimation.value + 1, 0),
                colors: [
                  widget.backgroundColor ?? Colors.grey[850]!,
                  Colors.grey[700]!,
                  widget.backgroundColor ?? Colors.grey[850]!,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Simple circle avatar with cached image and shimmer loading
class CachedCircleAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Widget? placeholder;

  const CachedCircleAvatar({
    required this.imageUrl,
    this.radius = 24,
    this.backgroundColor,
    this.placeholder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Use app logo as fallback when no valid profile image exists
    final trimmed = imageUrl.trim();
    final fallbackLogo = AppProperties.getAppLogoUrl().trim();
    final effectiveUrl = isValidNetworkImageUrl(trimmed)
        ? trimmed
        : (isValidNetworkImageUrl(fallbackLogo) ? fallbackLogo : '');

    if (effectiveUrl.isEmpty) {
      // Use the local app logo asset as last resort
      final logoPath = AppFlavour.getAppLogoPath();
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[800],
        backgroundImage: AssetImage(logoPath),
      );
    }

    if (kIsWeb) {
      final diameter = radius * 2;
      return Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.grey[800],
          shape: BoxShape.circle,
        ),
        child: buildWebNativeImage(
          imageUrl: effectiveUrl,
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
          circular: true,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: effectiveUrl,
      httpHeaders: neomImageHttpHeaders,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
        backgroundColor: backgroundColor,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[800],
        child: placeholder ??
            SizedBox(
              width: radius,
              height: radius,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey[600],
              ),
            ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[800],
        child: Icon(
          Icons.person,
          size: radius,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
