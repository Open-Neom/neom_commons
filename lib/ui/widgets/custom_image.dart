import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';

Widget cachedNetworkProfileImage(String profileId, String mediaUrl) {
  return GestureDetector(
    child: CachedNetworkImage(
      key: ValueKey(mediaUrl),
        imageUrl: mediaUrl,
        fit: BoxFit.fitHeight,
        placeholder: (context, url) => const CircularProgressIndicator(),
        errorWidget: (context,url,error) => const Icon(Icons.image_not_supported),
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
      child: CachedNetworkImage(
        key: ValueKey(mediaUrl),
        imageUrl: thumbnailUrl,
        fit: BoxFit.cover,
        errorWidget: (context,url,error) => const Icon(
          Icons.error,
        ),
      ),
    // ),
    onTap: () => Sint.toNamed(AppRouteConstants.videoFullScreen, arguments: [mediaUrl]),
  );
}
