import 'package:flutter/material.dart';
import 'package:sint/sint.dart';
import 'package:neom_core/app_properties.dart';
import 'package:neom_core/domain/model/event.dart';
import 'package:neom_core/domain/model/post.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/post_type.dart';

import 'custom_image.dart';
import 'images/handled_cached_network_image.dart';

class PostTile extends StatelessWidget {

  final Post post;
  final Event? event;

  const PostTile(this.post, this.event, {super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
    child: post.type == PostType.image ?
      HandledCachedNetworkImage(post.mediaUrl,
        function: () => Sint.toNamed(AppRouteConstants.postDetailsFullScreen, arguments: [post]),
      ) : post.type == PostType.video ?
      cachedVideoThumbnail(thumbnailUrl: post.thumbnailUrl, mediaUrl: post.mediaUrl)
        : HandledCachedNetworkImage(event?.imgUrl ?? AppProperties.getNoImageUrl(),
        function: () => Sint.toNamed(AppRouteConstants.postDetailsFullScreen, arguments: [post]),
      ),
      onTap: () => Sint.toNamed(AppRouteConstants.postDetailsFullScreen, arguments: [post])
    );
  }

}
//
