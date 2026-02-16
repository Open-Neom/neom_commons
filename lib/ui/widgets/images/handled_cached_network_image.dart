import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

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

  const HandledCachedNetworkImage(
    this.mediaUrl, {
    this.fit = BoxFit.fill,
    this.height,
    this.width,
    this.enableFullScreen = true,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.function,
    this.borderRadius,
    this.showProgress = false,
    this.placeholder,
    this.backgroundColor,
    super.key,
  });

  @override
  State<HandledCachedNetworkImage> createState() =>
      _HandledCachedNetworkImageState();
}

class _HandledCachedNetworkImageState extends State<HandledCachedNetworkImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  String? _errorMessage;

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
        _errorMessage = null;
      });
    }
  }

  String get _effectiveUrl {
    if (widget.mediaUrl.isNotEmpty && widget.mediaUrl != 'null') {
      return widget.mediaUrl;
    }
    final fallback = AppProperties.getAppLogoUrl();
    // Validate fallback URL is not null or the literal string "null"
    if (fallback.isNotEmpty && fallback != 'null' && fallback.startsWith('http')) {
      return fallback;
    }
    // Return a transparent 1x1 pixel as ultimate fallback to avoid exception
    return 'https://upload.wikimedia.org/wikipedia/commons/c/ce/Transparent.gif';
  }

  @override
  Widget build(BuildContext context) {
    final content = CachedNetworkImage(
      key: ValueKey('$_effectiveUrl-$_retryCount'),
      imageUrl: _effectiveUrl,
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
      fadeInDuration: widget.fadeInDuration,
      placeholder: (context, url) => _buildPlaceholder(),
      progressIndicatorBuilder: widget.showProgress
          ? (context, url, progress) => _buildProgressIndicator(progress)
          : null,
      errorWidget: (context, url, error) {
        _errorMessage = error.toString();
        return _buildErrorWidget();
      },
    );

    final wrappedContent = widget.borderRadius != null
        ? ClipRRect(borderRadius: widget.borderRadius!, child: content)
        : content;

    return GestureDetector(
      onTap: _handleTap,
      child: wrappedContent,
    );
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) return widget.placeholder!;

    return AnimatedBuilder(
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
    if (imageUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[800],
        child: Icon(
          Icons.person,
          size: radius,
          color: Colors.grey[600],
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
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
