import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_core/core/app_properties.dart';
import 'package:neom_core/core/utils/constants/app_route_constants.dart';

class HandledCachedNetworkImage extends StatelessWidget {

  final String mediaUrl;
  final BoxFit fit;
  final double? height;
  final double? width;
  final bool enableFullScreen;
  final Function()? function;


  const HandledCachedNetworkImage(this.mediaUrl, {
    this.fit = BoxFit.fill, this.height, this.width, this.enableFullScreen = true,
    this.function, super.key
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: CachedNetworkImage(
        imageUrl: mediaUrl.isNotEmpty ? mediaUrl : AppProperties.getAppLogoUrl(),
        height: height,
        width: width,
        fit: fit,
        // placeholder: (context, url) => const CircularProgressIndicator(),
        errorWidget: (context,url,error) => const Icon(Icons.image_not_supported),
      ),
      onTap: () => function != null ? function!() : enableFullScreen
          ? Get.toNamed(AppRouteConstants.mediaFullScreen, arguments: [mediaUrl])
          : null
    );
  }

}
