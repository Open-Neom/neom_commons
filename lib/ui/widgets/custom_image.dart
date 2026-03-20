import 'package:cached_network_image/cached_network_image.dart';
import 'package:neom_core/utils/platform/core_io.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

import 'images/web_network_image_stub.dart'
    if (dart.library.html) 'images/web_network_image_impl.dart';

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
ImageProvider platformImageProvider(String imageUrl, {int? maxHeight, int? maxWidth}) {
  final optimizedUrl = _optimizeGoogleImageUrl(imageUrl);
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
  if (uri == null) return url;
  final host = uri.host;
  if (!host.contains('googleusercontent.com')) return url;
  // Already has a size parameter (=sN or =s128-c0x...)
  if (url.contains(RegExp(r'=s\d+'))) return url;
  // Append size parameter
  return '$url=s$size';
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
  final optimizedUrl = _optimizeGoogleImageUrl(imageUrl);

  if (kIsWeb) {
    // On web, use Image.network (Flutter-rendered) instead of HtmlElementView.
    // HtmlElementView creates a platform view that floats above the Flutter
    // canvas, making ClipOval ineffective. Image.network goes through
    // Flutter's rendering pipeline and can be properly clipped into a circle.
    if (optimizedUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: fallbackChild,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: ClipOval(
        child: Image.network(
          optimizedUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => fallbackChild,
        ),
      ),
    );
  }
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
