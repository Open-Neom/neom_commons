import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

/// Platform-aware network image widget.
/// Uses Image.network on web (avoids CORS issues with canvas decoding)
/// and CachedNetworkImage on mobile (caching + better UX).
Widget platformNetworkImage({
  required String imageUrl,
  Key? key,
  BoxFit fit = BoxFit.cover,
  double? height,
  double? width,
  Widget? placeholder,
  Widget? errorWidget,
}) {
  if (kIsWeb) {
    return Image.network(
      imageUrl,
      key: key,
      fit: fit,
      height: height,
      width: width,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (context, error, stackTrace) =>
          errorWidget ?? const Icon(Icons.image_not_supported),
    );
  }
  return CachedNetworkImage(
    key: key,
    imageUrl: imageUrl,
    fit: fit,
    height: height,
    width: width,
    placeholder: (context, url) =>
        placeholder ?? const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    errorWidget: (context, url, error) =>
        errorWidget ?? const Icon(Icons.image_not_supported),
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
    Sint.toNamed(AppRouteConstants.mateDetails, arguments: profileId)
        : Sint.toNamed(AppRouteConstants.profileDetails, arguments: profileId),
  );
}

Widget fileImage(File mediaFile) {
  return GestureDetector(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(mediaFile,
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
