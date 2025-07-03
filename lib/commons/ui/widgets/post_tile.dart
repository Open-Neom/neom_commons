import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:neom_core/core/app_properties.dart';
import 'package:neom_core/core/domain/model/event.dart';
import 'package:neom_core/core/domain/model/post.dart';
import 'package:neom_core/core/utils/constants/app_route_constants.dart';
import 'package:neom_core/core/utils/enums/post_type.dart';

import 'custom_image.dart';

class PostTile extends StatelessWidget {

  final Post post;
  final Event? event;

  const PostTile(this.post, this.event, {super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
    child: post.type == PostType.image ?
      customCachedNetworkImage(post.mediaUrl)
        : post.type == PostType.video ?
      cachedVideoThumbnail(thumbnailUrl: post.thumbnailUrl, mediaUrl: post.mediaUrl)
        : customCachedNetworkImage(event?.imgUrl ?? AppProperties.getNoImageUrl()),
      onTap:()=> {
        //TODO VERIFY ITS WORKING
        //Get.delete<PostDetailsController>(),
        Get.toNamed(AppRouteConstants.postDetailsFullScreen, arguments: [post])
      }
    );
  }

}
//
