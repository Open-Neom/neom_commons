import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_core/data/implementations/user_controller.dart';
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
    onTap: () => Get.find<UserController>().profile.id != profileId ?
    Get.toNamed(AppRouteConstants.mateDetails, arguments: profileId)
        : Get.toNamed(AppRouteConstants.profileDetails, arguments: profileId),
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
      onTap: () => Get.toNamed(AppRouteConstants.imageFullScreen, arguments: [mediaFile.path, false])
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
    onTap: () => Get.toNamed(AppRouteConstants.videoFullScreen, arguments: [mediaUrl]),
  );
}
