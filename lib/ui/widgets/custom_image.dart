import 'package:cached_network_image/cached_network_image.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/platform/core_io.dart';
import 'package:neom_core/utils/release_catalog_visibility.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

import 'images/web_network_image_stub.dart'
    if (dart.library.js_interop) 'images/web_network_image_impl.dart';

/// Platform-aware network image widget.
/// On web: uses native HTML <img> via HtmlElementView to bypass CanvasKit CORS.
/// On mobile: uses CachedNetworkImage for disk caching + better UX.
Widget platformNetworkImage({
  required String imageUrl,
  Key? key,
  BoxFit fit = BoxFit.cover,
  double? height,
  double? width,
  Widget? placeholder,
  Widget? errorWidget,
}) {
  final optimizedUrl = _optimizeGoogleImageUrl(imageUrl);
  if (ReleaseCatalogVisibility.usesUnavailableHost(
    optimizedUrl,
    app: AppConfig.instance.appInUse,
  )) {
    final fallback = errorWidget ?? const Icon(Icons.image_not_supported);
    if (height == null && width == null) return fallback;
    return SizedBox(height: height, width: width, child: fallback);
  }
  if (kIsWeb) {
    return buildWebNativeImage(
      imageUrl: optimizedUrl,
      fit: fit,
      height: height,
      width: width,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
  return CachedNetworkImage(
    key: key,
    imageUrl: optimizedUrl,
    fit: fit,
    height: height,
    width: width,
    placeholder: (context, url) =>
        placeholder ?? const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    errorWidget: (context, url, error) =>
        errorWidget ?? const Icon(Icons.image_not_supported),
  );
}

/// Platform-aware image provider.
/// On web: returns NetworkImage (works for same-origin and CORS-enabled URLs
/// like Google, Firebase Storage, etc.). For cross-origin URLs without CORS,
/// use platformNetworkImage() or platformCircleAvatar() instead.
/// On mobile: returns CachedNetworkImageProvider for disk caching.
/// NOTE: Do NOT use webHtmlElementStrategy: prefer — it loads via HTML <img>
/// but then fails with EncodingError when extracting pixels for Canvas painting.
final Uint8List _transparentPlaceholderPng = Uint8List.fromList(const <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

ImageProvider platformImageProvider(String imageUrl, {int? maxHeight, int? maxWidth}) {
  final optimizedUrl = _optimizeGoogleImageUrl(imageUrl);
  if (ReleaseCatalogVisibility.usesUnavailableHost(
    optimizedUrl,
    app: AppConfig.instance.appInUse,
  )) {
    return MemoryImage(_transparentPlaceholderPng);
  }
  if (kIsWeb) {
    return NetworkImage(optimizedUrl);
  }
  return CachedNetworkImageProvider(optimizedUrl, maxHeight: maxHeight, maxWidth: maxWidth);
}

/// Optimizes Google user content image URLs by appending a size parameter.
/// Google's lh3/lh6.googleusercontent.com URLs support `=sN` suffix to
/// request a specific size, reducing bandwidth and avoiding HTTP 429 rate limits.
String _optimizeGoogleImageUrl(String url, {int size = 96}) {
  if (url.isEmpty) return url;
  final uri = Uri.tryParse(url);
  if (uri == null || uri.hasQuery || uri.hasFragment) return url;
  final host = uri.host.toLowerCase();
  if (host != 'googleusercontent.com' &&
      !host.endsWith('.googleusercontent.com')) {
    return url;
  }
  // Already has a size parameter (=sN or =s128-c0x...)
  if (url.contains(RegExp(r'=s\d+'))) return url;
  // Append size parameter
  return '$url=s$size';
}

/// Web circle avatar with automatic retry on 429/CORS errors.
/// First attempt uses the original URL (browser cache friendly).
/// On failure, retries once after 2s with =s96 optimized URL.
class _WebRetryCircleAvatar extends StatefulWidget {
  final String imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Widget fallbackChild;

  const _WebRetryCircleAvatar({
    required this.imageUrl,
    required this.radius,
    this.backgroundColor,
    required this.fallbackChild,
  });

  @override
  State<_WebRetryCircleAvatar> createState() => _WebRetryCircleAvatarState();
}

class _WebRetryCircleAvatarState extends State<_WebRetryCircleAvatar> {
  late String _currentUrl;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.imageUrl;
  }

  @override
  void didUpdateWidget(_WebRetryCircleAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _currentUrl = widget.imageUrl;
      _attempt = 0;
    }
  }

  void _onError(Object error, StackTrace? stackTrace) {
    if (!mounted || _attempt >= 3) return;
    _attempt++;
    // Exponential backoff: 3s, 6s, 12s — gives Google time to un-throttle
    final delay = Duration(seconds: 3 * _attempt);
    Future.delayed(delay, () {
      if (!mounted) return;
      setState(() {
        // Alternate between optimized and original URL
        _currentUrl = _attempt.isOdd
            ? _optimizeGoogleImageUrl(widget.imageUrl)
            : widget.imageUrl;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      backgroundImage: NetworkImage(_currentUrl),
      onBackgroundImageError: _onError,
    );
  }
}

/// Platform-aware circular avatar for network images.
/// On web: uses Image.network + ClipOval (Flutter-rendered, properly clippable).
/// On mobile: uses standard CircleAvatar with CachedNetworkImageProvider.
/// Use this instead of CircleAvatar(backgroundImage: platformImageProvider(...))
Widget platformCircleAvatar({
  required String imageUrl,
  double radius = 20,
  Color? backgroundColor,
  Widget? child,
}) {
  final bgColor = backgroundColor ?? Colors.grey[800];
  final fallbackChild = child ?? Icon(Icons.person, size: radius);

  if (kIsWeb) {
    final webUrl = imageUrl.trim();
    if (webUrl.isEmpty || !webUrl.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: fallbackChild,
      );
    }
    return _WebRetryCircleAvatar(
      imageUrl: webUrl,
      radius: radius,
      backgroundColor: bgColor,
      fallbackChild: fallbackChild,
    );
  }
  final optimizedUrl = _optimizeGoogleImageUrl(imageUrl);
  return CircleAvatar(
    radius: radius,
    backgroundColor: bgColor,
    backgroundImage: optimizedUrl.isNotEmpty
        ? CachedNetworkImageProvider(optimizedUrl)
        : null,
    child: imageUrl.isEmpty ? fallbackChild : child,
  );
}

/// Platform-aware BoxDecoration with network image.
/// On web: returns plain decoration (no image) since DecorationImage
/// paints on Canvas which requires CORS. Use a Stack with
/// platformNetworkImage instead for web backgrounds.
/// On mobile: returns BoxDecoration with DecorationImage.
BoxDecoration? platformDecorationImage({
  required String imageUrl,
  BoxFit fit = BoxFit.cover,
  ColorFilter? colorFilter,
  BorderRadius? borderRadius,
  Color? color,
}) {
  if (imageUrl.isEmpty) return null;
  if (kIsWeb) {
    // On web, DecorationImage paints on Canvas → CORS error.
    // Return decoration without image; caller should layer
    // platformNetworkImage in a Stack.
    return BoxDecoration(borderRadius: borderRadius, color: color);
  }
  return BoxDecoration(
    borderRadius: borderRadius,
    color: color,
    image: DecorationImage(
      image: CachedNetworkImageProvider(_optimizeGoogleImageUrl(imageUrl)),
      fit: fit,
      colorFilter: colorFilter,
    ),
  );
}

Widget cachedNetworkProfileImage(String profileId, String mediaUrl) {
  return GestureDetector(
    child: platformNetworkImage(
      imageUrl: mediaUrl,
      key: ValueKey(mediaUrl),
      fit: BoxFit.fitHeight,
    ),
    onTap: () => Sint.find<UserService>().profile.id != profileId ?
    Sint.toNamed(AppRouteConstants.matePath(profileId), arguments: profileId)
        : Sint.toNamed(AppRouteConstants.profilePath(profileId), arguments: profileId),
  );
}

Widget fileImage(File mediaFile) {
  return GestureDetector(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(mediaFile as dynamic,
            fit: BoxFit.fitHeight,
          ),
        ),
      onTap: () => Sint.toNamed(AppRouteConstants.imageFullScreen, arguments: [mediaFile.path, false])
  );
}

Widget cachedVideoThumbnail({required String thumbnailUrl, required String mediaUrl}) {
  return GestureDetector(
    child: platformNetworkImage(
      imageUrl: thumbnailUrl,
      key: ValueKey(mediaUrl),
      fit: BoxFit.cover,
    ),
    onTap: () => Sint.toNamed(AppRouteConstants.videoFullScreen, arguments: [mediaUrl]),
  );
}
